//
//  PNIAPSK2Bridge.swift
//  footBall
//
//  StoreKit 2 桥接实现。
//
//  设计要点：
//  1. 客户端主要购买流程仍由 OC 端 SK1 驱动（SKPaymentQueue.addPayment），
//     这样 iOS 13/14 也能跑通。
//  2. iOS 15+ 时，SK1 完成购买后，用 SK1 transactionId 在 SK2 侧匹配，
//     取 VerificationResult.jwsRepresentation（真正的 JWS）上报服务端。
//  3. 服务端拿到 JWS 后走 AppleIAPProxyImpl.verifyViaJws 验签，
//     不依赖 Server API v2 的 .p8（.p8 未配齐时仍可沙箱联调）。
//
//  注意：Transaction.jsonRepresentation 是「交易字段的 JSON Data」，
//  不是 JWS！误用会导致服务端 JWSObject.parse 失败 → 060001 验证失败。
//

import Foundation
import StoreKit

@objc(PNIAPSK2Result)
public class PNIAPSK2Result: NSObject {
    @objc public let transactionId: String
    @objc public let jwsRepresentation: String
    @objc public let isRestore: Bool

    @objc public init(transactionId: String, jwsRepresentation: String, isRestore: Bool) {
        self.transactionId = transactionId
        self.jwsRepresentation = jwsRepresentation
        self.isRestore = isRestore
        super.init()
    }
}

@objc(PNIAPSK2Bridge)
public class PNIAPSK2Bridge: NSObject {

    @objc public static func isAvailable() -> Bool {
        if #available(iOS 15.0, *) {
            return true
        }
        return false
    }

    /// 用 SK1 transactionId 在 SK2 事务中匹配，返回真正的 JWS。
    /// 查找顺序：currentEntitlements → unfinished（刚购买尚未 finish 时更可能在这里）。
    @objc public static func currentJWS(
        forTransactionId transactionId: String,
        completion: @escaping (PNIAPSK2Result?) -> Void
    ) {
        guard isAvailable(), !transactionId.isEmpty else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        // SK1 transactionId 是数字字符串，转 UInt64 与 SK2 Transaction.id 比较
        guard let targetId = UInt64(transactionId) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        Task.detached(priority: .userInitiated) {
            if #available(iOS 15.0, *) {
                // 1) 当前权益（订阅/非消耗型已完成购买）
                if let hit = await Self.findJWS(targetId: targetId, in: Transaction.currentEntitlements) {
                    await MainActor.run { completion(hit) }
                    return
                }
                // 2) 未 finish 队列（SK1 刚 Purchased、尚未 finish 时常在这里）
                if let hit = await Self.findJWS(targetId: targetId, in: Transaction.unfinished) {
                    await MainActor.run { completion(hit) }
                    return
                }
                await MainActor.run { completion(nil) }
            } else {
                await MainActor.run { completion(nil) }
            }
        }
    }

    @available(iOS 15.0, *)
    private static func findJWS(
        targetId: UInt64,
        in transactions: Transaction.Transactions
    ) async -> PNIAPSK2Result? {
        for await verification in transactions {
            guard case .verified(let txn) = verification else { continue }
            guard txn.id == targetId else { continue }
            // 关键：必须用 VerificationResult.jwsRepresentation（三段式 JWS），
            // 不能用 Transaction.jsonRepresentation（那是普通 JSON，服务端验签必挂）。
            let jws = verification.jwsRepresentation
            guard jws.split(separator: ".").count >= 3 else { return nil }
            return PNIAPSK2Result(
                transactionId: String(txn.id),
                jwsRepresentation: jws,
                isRestore: false
            )
        }
        return nil
    }

    /// SK2 路径 finish 事务。SK1 路径已 finish 的事务无需调用。
    /// 仅在「完全由 SK2 发起购买」的场景使用，当前流程未启用此场景。
    @objc public static func finishTransaction(byId transactionId: String) {
        guard isAvailable(), !transactionId.isEmpty,
              let targetId = UInt64(transactionId) else {
            return
        }
        Task.detached(priority: .background) {
            if #available(iOS 15.0, *) {
                do {
                    let result = try await Transaction.unfinished
                        .first(where: { r in
                            if case .verified(let t) = r { return t.id == targetId }
                            return false
                        })
                    if case .verified(let txn) = result {
                        await txn.finish()
                    }
                } catch {
                    // 静默失败：SK1 finishTransaction 会兜底，不会导致队列堆积
                }
            }
        }
    }
}
