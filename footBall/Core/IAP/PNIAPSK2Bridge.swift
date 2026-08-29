//
//  PNIAPSK2Bridge.swift
//  footBall
//
//  StoreKit 2 桥接实现。
//
//  注意：Transaction.jsonRepresentation 是「交易字段的 JSON Data」，
//  不是 JWS！必须用 VerificationResult.jwsRepresentation。
//

import Foundation
import StoreKit

@objc(PNIAPSK2Result)
public class PNIAPSK2Result: NSObject {
    @objc public let transactionId: String
    @objc public let jwsRepresentation: String
    @objc public let isRestore: Bool
    @objc public let productId: String

    @objc public init(transactionId: String, jwsRepresentation: String, isRestore: Bool, productId: String) {
        self.transactionId = transactionId
        self.jwsRepresentation = jwsRepresentation
        self.isRestore = isRestore
        self.productId = productId
        super.init()
    }

    /// 兼容旧 OC 调用（无 productId 时传空串）
    @objc public convenience init(transactionId: String, jwsRepresentation: String, isRestore: Bool) {
        self.init(transactionId: transactionId, jwsRepresentation: jwsRepresentation, isRestore: isRestore, productId: "")
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
    @objc public static func currentJWS(
        forTransactionId transactionId: String,
        completion: @escaping (PNIAPSK2Result?) -> Void
    ) {
        guard isAvailable(), !transactionId.isEmpty else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        guard let targetId = UInt64(transactionId) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        Task.detached(priority: .userInitiated) {
            if #available(iOS 15.0, *) {
                if let hit = await Self.findJWS(targetId: targetId, in: Transaction.currentEntitlements) {
                    await MainActor.run { completion(hit) }
                    return
                }
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

    /// 枚举当前有效权益，供「恢复购买」在 SK1 restore 0 笔时补激活。
    @objc public static func enumerateCurrentEntitlements(
        _ completion: @escaping ([PNIAPSK2Result]) -> Void
    ) {
        guard isAvailable() else {
            DispatchQueue.main.async { completion([]) }
            return
        }
        Task.detached(priority: .userInitiated) {
            var collected: [PNIAPSK2Result] = []
            if #available(iOS 15.0, *) {
                for await verification in Transaction.currentEntitlements {
                    guard case .verified(let txn) = verification else { continue }
                    let jws = verification.jwsRepresentation
                    guard jws.split(separator: ".").count >= 3 else { continue }
                    collected.append(PNIAPSK2Result(
                        transactionId: String(txn.id),
                        jwsRepresentation: jws,
                        isRestore: true,
                        productId: txn.productID
                    ))
                }
            }
            await MainActor.run { completion(collected) }
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
            let jws = verification.jwsRepresentation
            guard jws.split(separator: ".").count >= 3 else { return nil }
            return PNIAPSK2Result(
                transactionId: String(txn.id),
                jwsRepresentation: jws,
                isRestore: false,
                productId: txn.productID
            )
        }
        return nil
    }

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
                    // 静默失败：SK1 finishTransaction 会兜底
                }
            }
        }
    }
}
