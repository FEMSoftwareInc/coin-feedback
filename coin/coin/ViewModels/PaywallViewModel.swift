import Foundation
import StoreKit
import Combine

@MainActor
class PaywallViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isPremium = false
    @Published var isLoading = false
    @Published var error: Error?
    
    private let productIDs = ["com.coin.premium.monthly", "com.coin.premium.yearly"]
    
    init() {
        Task {
            await loadProducts()
            await checkPurchaseStatus()
        }
    }
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
    
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try verification.payloadValue
                await transaction.finish()
                isPremium = true
                
            case .pending:
                break
                
            case .userCancelled:
                break
                
            @unknown default:
                break
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
    
    func checkPurchaseStatus() async {
        do {
            for await result in Transaction.currentEntitlements {
                let transaction = try result.payloadValue
                
                if productIDs.contains(transaction.productID) {
                    isPremium = true
                    return
                }
            }
            
            isPremium = false
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
            isPremium = false
        }
    }
}
