import Foundation
import StoreKit
import Combine

@MainActor
class PurchaseManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isProUser = false
    @Published var isLoading = false
    @Published var error: Error?
    @Published var purchaseInProgress = false
    
    private let productIDs = [
        "com.femsoftware.coinfeedback.pro.monthly",
        "com.femsoftware.coinfeedback.pro.yearly",
        "com.femsoftware.coinfeedback.pro.lifetime"
    ]
    
    private var updateTask: Task<Void, Never>?
    
    init() {
        Task {
            await setupTransactionListener()
            await loadProducts()
            await checkProStatus()
        }
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            products = try await Product.products(for: productIDs)
                .sorted { ($0.subscription?.subscriptionPeriod.value ?? 0) < ($1.subscription?.subscriptionPeriod.value ?? 0) }
        } catch {
            self.error = error
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase Handling
    
    func purchase(_ product: Product) async -> Bool {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                do {
                    let transaction = try verification.payloadValue
                    await transaction.finish()
                    await checkProStatus()
                    return true
                } catch {
                    self.error = error
                    print("Transaction verification failed: \(error)")
                    return false
                }
                
            case .pending:
                print("Purchase pending")
                return false
                
            case .userCancelled:
                print("Purchase cancelled by user")
                return false
                
            @unknown default:
                print("Unknown purchase result")
                return false
            }
        } catch {
            self.error = error
            print("Purchase failed: \(error)")
            return false
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
            await checkProStatus()
            return true
        } catch {
            self.error = error
            print("Restore purchases failed: \(error)")
            return false
        }
    }
    
    // MARK: - Transaction Listening
    
    private func setupTransactionListener() async {
        updateTask = Task(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let transaction = try result.payloadValue
                    await transaction.finish()
                    await checkProStatus()
                } catch {
                    print("Transaction update failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Pro Status Checking
    
    func checkProStatus() async {
        do {
            var isProNow = false
            
            // Check all active transactions/subscriptions
            for await result in Transaction.currentEntitlements {
                do {
                    let transaction = try result.payloadValue
                    
                    // Check if it's one of our products
                    if productIDs.contains(transaction.productID) {
                        // Check if the transaction hasn't been revoked
                        // (works for both subscriptions and non-consumables)
                        if transaction.revocationDate == nil {
                            isProNow = true
                            break
                        }
                    }
                } catch {
                    print("Error processing entitlement: \(error)")
                }
            }
            
            self.isProUser = isProNow
        } catch {
            self.error = error
            print("Failed to check pro status: \(error)")
            self.isProUser = false
        }
    }
    
    deinit {
        updateTask?.cancel()
    }
}
