

import Foundation
import StoreKit

enum Product: String, CaseIterable {
    case removeAds = "org.kivy.wraptest.noads0"
}


class InAppHandler: NSObject {
    
    var MyProduct: SKProduct?
    
    
    
    func fetchProducts(product: String) {
        //org.kivy.wraptest.noads
        let main_string = "org.kivy.wraptest."
        let id = main_string.appending(product)
        
        print("fetching product \(id)")
        let request = SKProductsRequest(productIdentifiers: Set([id]))
        request.delegate = self
        request.start()
    }
    
    
    
}

extension InAppHandler: SKProductsRequestDelegate, SKPaymentTransactionObserver {
    internal func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("productsRequest",response.products)
        if let product = response.products.first {
            MyProduct = product
            print(product.productIdentifier)
            print(product.price)
            print(product.localizedTitle)
            print(product.localizedDescription)
            print(product.priceLocale)
        }
        print("MyProduct",MyProduct)
    }
    
    internal func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("paymentQueue", transactions)
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                break
            case .purchased, .restored:
                // unlock item
                SKPaymentQueue.default().finishTransaction(transaction)
                SKPaymentQueue.default().remove(self )
                break
            case .failed, .deferred:
                SKPaymentQueue.default().finishTransaction(transaction)
                SKPaymentQueue.default().remove(self)
                break
            default:
                SKPaymentQueue.default().finishTransaction(transaction)
                SKPaymentQueue.default().remove(self)
                break
            }
        }
    }
}


extension InAppHandler {
    
    
    func didBuy() {
        guard let myProduct = MyProduct else {return}
        if SKPaymentQueue.canMakePayments() {
            let payment = SKPayment(product: myProduct)
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)
        }
    }
}





