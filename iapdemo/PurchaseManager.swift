//
//  PurchaseManager.swift
//  iapinstorekit2
//
//  Created by zh on 2023/11/17.
//

import Foundation
import StoreKit

@objcMembers public class PurchaseManager: NSObject {
    
    /// 发起支付
    /// - Parameters:
    ///   - uid: UUID String
    ///   - productId: Product ID
    /// - Returns: 支付结果
    public func purchase(uid: String, productId: String) async -> Dictionary<String, Any> {
        let purchaseManager: Store = Store()
        
        // 发起内购
        Task.init {
            do {
                let transaction = try await purchaseManager.purchase(from: productId, uid: uid)
                
                //支付完成，发送凭据给服务端验证，请求发货。
                if transaction != nil {
                    print("支付完成")
                    print("transaction id: \(transaction!.originalID),  purchase date:\(transaction!.originalPurchaseDate), user id:\(String(describing: transaction!.appAccountToken!))")
                    
                    return ["transactionId": transaction!.originalID,
                            "uuid": transaction!.appAccountToken!.uuidString]
                }
                
                return [:]
            } catch PurchaseException.noProductMatched {
                return ["code": PurchaseException.noProductMatched,
                        "error": "商品不存在，请检查Product ID"]
            } catch PurchaseException.transactionVerificationFailed {
                return ["code": PurchaseException.transactionVerificationFailed,
                        "error": "凭据验证失败"]
            } catch PurchaseException.purchaseInProgressException {
                return ["code": PurchaseException.purchaseInProgressException,
                        "error": "等待（家庭用户才有的状态）"]
            } catch PurchaseException.purchaseException {
                return ["code": PurchaseException.purchaseException,
                        "error": "服务器异常"]
            }
        }
        
        return ["info" : "Purchase started."]
    }
    
    /// 发起退款
    /// - Parameters:
    ///   - transactionId: transaction.originalID
    ///   - scene: Window scene
    public func refunRequest(for transactionId: UInt64, scene: UIWindowScene!) async {
        do {
            let res = try await Transaction.beginRefundRequest(for: transactionId, in: scene)
            switch res {
            case .userCancelled:
                // Customer cancelled refund request.
                print("用户取消退款。")
            case .success:
                print("退款提交成功。")
                // Refund request was successfully submitted.
            @unknown default:
                print("退款返回错误：未知")
            }
        }
        catch StoreKit.Transaction.RefundRequestError.duplicateRequest {
            print("退款请求错误：重复请求")
        }
        catch StoreKit.Transaction.RefundRequestError.failed {
            print("退款请求错误：失败")
        }
        catch {
            print("退款请求错误：其他")
        }
    }
    
    
    
}
