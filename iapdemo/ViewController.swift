//
//  ViewController.swift
//  iapdemo
//
//  Created by zm on 2024/4/15.
//

import UIKit
import StoreKit

class ViewController: UIViewController {
    let purchaseManager = PurchaseManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    // 点击购买
    @IBAction func toPurchase(_ sender: Any) {
        Task { @MainActor in
            let res = await purchaseManager.purchase(uid: "68753A44-4D6F-1386-8C69-0050E4C00067", productId: "your-product-id")
            
            print(res)
        }
    }
    
    // 点击退款
    @IBAction func toRefund(_ sender: Any)  {
        Task { @MainActor in
            await purchaseManager.refunRequest(for: 2000000572764080, scene: self.view.window?.windowScene)
        }
    }
    
}

