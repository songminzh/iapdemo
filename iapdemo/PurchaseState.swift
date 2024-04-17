//
//  PurchaseState.swift
//  iapinstorekit2
//
//  Created by zm on 2023/11/14.
//

import Foundation

public enum PurchaseState {
    case notStarted
    case inProgress
    case complete
    case pending
    case cancelled
    case failed
    case failedVerification
    case unknown
}
