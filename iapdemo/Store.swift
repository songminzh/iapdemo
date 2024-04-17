//
//  InAppPurchaseManager.swift
//  iapinstorekit2
//
//  Created by zm on 2023/11/14.
//

import Foundation
import StoreKit

typealias Transaction = StoreKit.Transaction
typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
typealias Renewwal = StoreKit.Product.SubscriptionInfo.RenewalState


class Store: NSObject, ObservableObject {
    @Published public var products: [Product]?
    
    private var purchaseState: PurchaseState = .notStarted
    
    /// Array of consumable products
    public var consumableProducts: [Product]? {
        guard products != nil else {
            return nil
        }
        
        return products?.filter({ product in
            product.type == .consumable
        })
    }
    
    /// Array of nonConsumbale productszhif
    public var nonConsumbaleProducts: [Product]? {
        guard products != nil else {
            return nil
        }
        
        return products?.filter({ product in
            product.type == .nonConsumable
        })
    }
    
    /// Array of subscriptio products
    public var subscriptionProducts: [Product]? {
        guard products != nil else {
            return nil
        }
        
        return products?.filter({ product in
            product.type == .autoRenewable
        })
    }
    
    /// Array of nonSubscription products
    public var nonSubscriptionProducts: [Product]? {
        guard products != nil else {
            return nil
        }
        
        return products?.filter({ product in
            product.type == .nonRenewable
        })
    }

    
    private var transactionListener: Task<Void, Error>? = nil
    
    override init() {
        super.init()
        
        //Listen for App Store transactions
        transactionListener = listenForTransaction()
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    @MainActor
    /// 通过 productIds 请求 Product 列表
    /// - Parameter productIds: product ids
    /// - Returns: Product 列表
    func requestProducts(productIds: [String]) async -> [Product]? {
        products = try? await Product.products(for: Set.init(productIds))
        return products
    }
        
    /// 通过productId获取商品对象（Product）
    /// - Parameter productId: product id
    /// - Returns: Product object
    public func product(from productId: String) async throws -> Product? {
        let storeProducts: [Product]? = try? await Product.products(for: Set.init([productId]))
        
        if storeProducts != nil, storeProducts!.count > 0 {
            return storeProducts!.first
        } else {
            throw PurchaseException.noProductMatched
        }
    }
    
    public func hasProduct() -> Bool {
        guard products != nil else {
            return false
        }
        
        return products!.count > 0 ? true : false
    }
    
    
    public func purchase(from productid: String, uid: String) async throws -> Transaction? {
        do {
            let product = try await product(from: productid)!
            return try await purchase(product: product, uid: uid)
        } catch PurchaseException.noProductMatched {
            throw PurchaseException.noProductMatched
        }
    }
    
    /// 发起支付
    /// - Parameter product: Product对象
    public func purchase(product: Product, uid: String) async throws -> Transaction? {
        guard purchaseState != .inProgress else {
            throw PurchaseException.purchaseInProgressException
        }
        
        purchaseState = .inProgress
        
        //App account token
        //用于将用户 ID 绑定到交易（Transcation）中，即可建立苹果的交易订单数据与用户信息的映射关系，方便数据整合与追溯
        let uuid = Product.PurchaseOption.appAccountToken(UUID.init(uuidString: uid)!)
        //发起支付流程
        guard let res = try? await product.purchase(options: [uuid]) else {
            purchaseState = .failed
            throw PurchaseException.transactionVerificationFailed
        }
        
        var validateTransaction: Transaction? = nil
        
        switch res {
        case .success(let verificationResult):
            //购买状态：成功
            
            print("用户购买成功")
            purchaseState = .complete
            
            let checkResult = checkTransactionVerificationResult(verificationResult)
            if !checkResult.verified {
                purchaseState = .failedVerification
                throw PurchaseException.transactionVerificationFailed
            }
            
            validateTransaction = checkResult.transaction
            
            //结束交易
            await validateTransaction!.finish()
            
        case .userCancelled:
            //购买状态：用户取消
            print("用户取消购买")
            purchaseState = .cancelled
            
        case .pending:
            //购买状态：进行中
            print("用户购买中")
            purchaseState = .pending
            
        default:
            //购买状态：未知
            print("用户购买状态：未知")
            purchaseState = .unknown
        }
        
        return validateTransaction
    }
    
    
    /// 支付监听事件
    private func listenForTransaction() -> Task<Void, Error> {
        return Task.detached {
            for await verificationResult in Transaction.updates {
                let checkResult = self.checkTransactionVerificationResult(verificationResult)
                
                if checkResult.verified {
                    let validatedTransaction = checkResult.transaction
                    await validatedTransaction.finish()
                } else {
                    print("Transaction failed verification.")
                }
            }
        }
    }
    
    
    /// 校验
    /// - Parameter result: 支付返回结果
    /// - Returns: 是否验证成功
    private func checkTransactionVerificationResult(_ result: VerificationResult<Transaction>) -> (transaction: Transaction, verified: Bool) {
        //Check whether the JWS parses StoreKit verification.
        switch result {
        case .unverified(let transaction, _):
            //StoreKit parses the JWS， but it fails verification.
            return (transaction: transaction, verified: false)
        case .verified(let transaction):
            //The reult is verified. Return the unwrapped value.
            return (transaction: transaction, verified: true)
        }
    }
}

