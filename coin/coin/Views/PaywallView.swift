import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var purchaseManager: PurchaseManager
    
    @State private var selectedProductID: String?
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var isRestoring = false
    
    var body: some View {
        ZStack {
            // Glassmorphism background gradient (matches Feedback Details)
            AppColors.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.2, green: 0.5, blue: 0.9),
                                        Color(red: 0.3, green: 0.6, blue: 0.95)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Unlock Premium")
                            .font(.system(size: 28, weight: .bold))
                            .tracking(0.5)
                        
                        Text("Get unlimited access to all features")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 16)
                    
                    // Benefits List
                    VStack(spacing: 12) {
                        BenefitRow(icon: "infinity", title: "Unlimited Entries", description: "Create as many feedback entries as you need")
                        BenefitRow(icon: "paperplane.fill", title: "Email Sharing", description: "Share your COIN feedback with anyone")
                        BenefitRow(icon: "chart.line.uptrend.xyaxis", title: "Share Tracking", description: "Track when entries are shared and with whom")
                        BenefitRow(icon: "icloud.fill", title: "iCloud Sync", description: "Sync your data across all your devices")
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.15))
                            .backdrop(blur: 20)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    
                    // Pricing Options
                    VStack(spacing: 12) {
                        Text("Choose Your Plan")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Sort products by price (ascending) for display
                        let sortedProducts = purchaseManager.products.sorted { product1, product2 in
                            product1.price < product2.price
                        }
                        
                        ForEach(sortedProducts, id: \.id) { product in
                            PricingOptionButton(
                                product: product,
                                allProducts: sortedProducts,
                                isSelected: selectedProductID == product.id,
                                action: {
                                    selectedProductID = product.id
                                }
                            )
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.15))
                            .backdrop(blur: 20)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    
                    // Purchase Button
                    if let selectedProductID = selectedProductID,
                       let selectedProduct = purchaseManager.products.first(where: { $0.id == selectedProductID }) {
                        Button(action: { purchaseProduct(selectedProduct) }) {
                            HStack {
                                if purchaseManager.purchaseInProgress {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Subscribe Now")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .foregroundColor(.white)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.2, green: 0.5, blue: 0.9),
                                        Color(red: 0.3, green: 0.6, blue: 0.95)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .disabled(purchaseManager.purchaseInProgress)
                    }
                    
                    // Restore Purchases Button
                    Button(action: { restorePurchases() }) {
                        if isRestoring {
                            ProgressView()
                                .tint(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Restore Purchases")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .foregroundColor(.secondary)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .disabled(isRestoring)
                    
                    // Maybe Later Button
                    Button(action: { dismiss() }) {
                        Text("Maybe Later")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .foregroundColor(.secondary)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    // Legal Text
                    VStack(spacing: 8) {
                        Text("Auto-renewing subscriptions")
                            .font(.system(size: 12, weight: .semibold))
                        
                        Text("Monthly and yearly subscriptions auto-renew unless cancelled 24 hours before the renewal date. Your subscription can be managed in Settings > Apps > Subscriptions. Lifetime purchase is a one-time payment.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(6)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                }
                .padding(20)
            }
        }
        .onAppear {
            // Set Yearly as default if available
            if let yearlyProduct = purchaseManager.products.first(where: { $0.id.contains("yearly") }) {
                selectedProductID = yearlyProduct.id
            } else {
                // Fallback to first sorted by price
                let sorted = purchaseManager.products.sorted { $0.price < $1.price }
                selectedProductID = sorted.first?.id
            }
        }
        .alert("Restore Purchases", isPresented: $showRestoreAlert) {
            Button("OK") { }
        } message: {
            Text(restoreMessage)
        }
    }
    
    private func purchaseProduct(_ product: Product) {
        Task {
            let success = await purchaseManager.purchase(product)
            if success {
                dismiss()
            }
        }
    }
    
    private func restorePurchases() {
        isRestoring = true
        Task {
            let success = await purchaseManager.restorePurchases()
            isRestoring = false
            
            if success {
                restoreMessage = "Purchases restored successfully!"
            } else {
                restoreMessage = "No purchases to restore, or restore failed."
            }
            showRestoreAlert = true
        }
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.5, blue: 0.9),
                            Color(red: 0.3, green: 0.6, blue: 0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

// MARK: - Pricing Option Button

struct PricingOptionButton: View {
    let product: Product
    let allProducts: [Product]
    let isSelected: Bool
    let action: () -> Void
    
    var displayName: String {
        switch product.id {
        case "com.femsoftware.coinfeedback.pro.monthly":
            return "Monthly"
        case "com.femsoftware.coinfeedback.pro.yearly":
            return "Yearly"
        case "com.femsoftware.coinfeedback.pro.lifetime":
            return "Lifetime"
        default:
            return product.displayName
        }
    }
    
    var savingPercentage: String? {
        // Only show savings for yearly compared to monthly
        guard product.id.contains("yearly") else { return nil }
        
        // Find monthly product to calculate savings
        guard let monthlyProduct = allProducts.first(where: { $0.id.contains("monthly") }) else {
            return nil
        }
        
        // Calculate yearly cost vs 12x monthly
        let monthlyPrice = NSDecimalNumber(decimal: monthlyProduct.price)
        let yearlyPrice = NSDecimalNumber(decimal: product.price)
        let monthlyAnnual = monthlyPrice.multiplying(by: 12)
        
        // Only show savings if yearly is actually cheaper
        guard yearlyPrice.compare(monthlyAnnual) == .orderedAscending else { return nil }
        
        let savings = monthlyAnnual.subtracting(yearlyPrice)
        let savingPercent = savings
            .dividing(by: monthlyAnnual)
            .multiplying(by: 100)
            .doubleValue
        
        return String(format: "Save ~%d%%", Int(savingPercent.rounded()))
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.system(size: 16, weight: .semibold))
                    Text(product.displayPrice)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let saving = savingPercentage {
                    Text(saving)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.2, green: 0.5, blue: 0.9),
                                    Color(red: 0.3, green: 0.6, blue: 0.95)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(6)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        isSelected ?
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.2, green: 0.5, blue: 0.9),
                                Color(red: 0.3, green: 0.6, blue: 0.95)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : LinearGradient(gradient: Gradient(colors: [.gray.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Backdrop Modifier

extension View {
    func backdrop(blur: CGFloat = 20) -> some View {
        self.modifier(BackdropBlurModifier(blur: blur))
    }
}

struct BackdropBlurModifier: ViewModifier {
    let blur: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .blur(radius: blur / 2)
            )
    }
}

#Preview {
    let manager = PurchaseManager()
    PaywallView(purchaseManager: manager)
}
