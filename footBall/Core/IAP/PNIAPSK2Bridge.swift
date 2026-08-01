//
//  PNIAPSK2Bridge.swift
//  footBall
//
//  StoreKit 2 桥接实现。
//
//  设计要点：
//  1. 客户端主要购买流程仍由 OC 端 SK1 驱动（SKPaymentQueue.addPayment），
//     这样 iOS 13/14 也能跑通。
//  2. iOS 15+ 时，SK1 完成购买后，SK2 的 Transaction.currentEntitlements
//     会同步看到这笔事务（SK1/SK2 共享底层队列）。本 bridge 用 SK1 transactionId
//     去 SK2 侧匹配，拿到 jsonRepresentation（JWS）上报服务端。
//  3. 服务端拿到 JWS 后走 AppleIAPProxyImpl.verifyViaJws 路径直接验签成功，
//     不再依赖 Server API v2 的 .p8 配置（修复 StoreKit 版本不匹配阻塞）。
//  4. SK1 transactionId 与 SK2 Transaction.id 的关系：
//     Apple 文档明确二者在同一笔交易上是相同的数字字符串。
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

    /// 用 SK1 transactionId 在 SK2 当前权益事务中匹配，返回 JWS。
    /// currentEntitlements 只返回已完成购买（与 SK1 Purchased 状态对应）。
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
                do {
                    // 遍历当前权益（已完成购买的非消耗型/订阅），按 transactionId 匹配
                    for await result in Transaction.currentEntitlements {
                        switch result {
                        case .verified(let txn):
                            if txn.id == targetId {
                                let jws = String(data: txn.jsonRepresentation, encoding: .utf8) ?? ""
                                let res = PNIAPSK2Result(
                                    transactionId: String(txn.id),
                                    jwsRepresentation: jws,
                                    isRestore: false
                                )
                                await MainActor.run { completion(res) }
                                return
                            }
                        case .unverified:
                            continue
                        }
                    }
                    // 未在 entitlements 命中（可能是消耗型，或事务已被 finish）：
                    // 回退到 SK1 路径，让调用方自行处理
                    await MainActor.run { completion(nil) }
                } catch {
                    await MainActor.run { completion(nil) }
                }
            } else {
                await MainActor.run { completion(nil) }
            }
        }
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
                    let result = try await Transaction.currentEntitlements
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
