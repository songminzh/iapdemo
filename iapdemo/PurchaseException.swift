//
//  PurchaseException.swift
//  iapinstorekit2
//
//  Created by zm on 2023/11/14.
//

import Foundation

public enum PurchaseException: Error, Equatable {
    case noProductMatched
    case purchaseException
    case purchaseInProgressException
    case transactionVerificationFailed
    
    public func shortDescription() -> String {
        switch self {
        case.noProductMatched:
            return "Exception: No product matched with the productId"
        case.purchaseException:
            return "Exception: StoreKit throw an exception while processing a purchase"
        case.purchaseInProgressException:
            return "Exception: You can't start another purchase yet, one is already in process"
        case .transactionVerificationFailed:
            return "Exception: A transaction failed Storekit's verification"
        }
    }
}
