import Observation
import StoreKit
import SwiftUI

/// Voluntary consumable tips only. This store never grants or restricts features.
@MainActor @Observable
final class SupportTipStore {
    static let shared = SupportTipStore()
    static let suffixes = ["small", "medium", "large"]
    let productIDs: [String]
    private(set) var products: [Product] = []
    private(set) var loading = false
    private(set) var purchasing = false
    var message: String?
    private var updates: Task<Void, Never>?

    init(bundleID: String = Bundle.main.bundleIdentifier ?? "") {
        productIDs = Self.suffixes.map { bundleID + ".tip." + $0 }
    }

    isolated deinit { updates?.cancel() }

    func start() {
        guard updates == nil else { return }
        updates = Task { [weak self] in
            for await update in StoreKit.Transaction.updates {
                guard let self else { return }
                await self.complete(update)
            }
        }
        Task { [weak self] in
            for await transaction in StoreKit.Transaction.unfinished {
                await self?.complete(transaction)
            }
        }
    }

    func load() async {
        start()
        guard !loading else { return }
        loading = true
        message = nil
        defer { loading = false }
        do {
            products = try await Product.products(for: productIDs)
                .filter { $0.type == .consumable }
                .sorted { $0.price < $1.price }
            if products.isEmpty {
                message = "Tips are unavailable right now. Please try again later. Everything in the app remains free."
            }
        } catch {
            message = "Could not connect to the App Store. Please check your connection and try again."
        }
    }

    func purchase(_ product: Product) async {
        guard !purchasing, productIDs.contains(product.id), product.type == .consumable else { return }
        purchasing = true
        defer { purchasing = false }
        do {
            await handle(try await product.purchase())
        } catch StoreKitError.userCancelled {
            // Closing Apple’s payment sheet is not an error.
        } catch {
            message = "The tip could not be completed. Please try again later."
        }
    }

    func handle(_ result: Product.PurchaseResult) async {
            switch result {
            case .success(let result): await complete(result)
            case .pending:
                message = "Your tip is awaiting approval. Apple will complete it when approved. You can keep using every feature."
            case .userCancelled: break
            @unknown default:
                message = "The purchase has not completed. Please try again later."
            }
    }

    private func complete(_ result: VerificationResult<StoreKit.Transaction>) async {
        switch result {
        case .verified(let transaction):
            guard productIDs.contains(transaction.productID), transaction.productType == .consumable else { return }
            await transaction.finish()
            if transaction.revocationDate == nil {
                message = "Thank you for supporting development! Every feature remains free for everyone."
            }
        case .unverified:
            message = "Apple could not verify this purchase. No additional purchase is needed; please try again later."
        }
    }
}

struct SupportDevelopmentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = SupportTipStore.shared

    var body: some View {
        NavigationStack {
            SwiftUI.Form {
                Section {
                    Label("Free, with your support", systemImage: "heart")
                        .font(.headline)
                    Text("If you enjoy the app, you can leave an optional tip to support its development.")
                    Text("Every feature is free. Tips do not unlock anything and are never required.")
                        .foregroundStyle(.secondary)
                }
                Section {
                    if store.loading {
                        ProgressView("Loading tips…")
                    } else if store.products.isEmpty {
                        Text("Tips are currently unavailable.")
                        Button("Try again") { Task { await store.load() } }
                            .accessibilityIdentifier("support.retry")
                    } else {
                        ForEach(store.products) { product in
                            Button {
                                Task { await store.purchase(product) }
                            } label: {
                                HStack {
                                    Text(product.displayName)
                                    Spacer(minLength: 16)
                                    Text(product.displayPrice)
                                        .monospacedDigit()
                                }
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .disabled(store.purchasing)
                            .accessibilityIdentifier("support.tip." + (product.id.split(separator: ".").last.map(String.init) ?? ""))
                        }
                    }
                    if store.purchasing { ProgressView("Waiting for the App Store…") }
                } header: {
                    Text("Leave a tip")
                } footer: {
                    Text("A one-off purchase, not a subscription. You can tip again whenever you choose. Payment is handled by Apple.")
                }
                if let message = store.message {
                    Section {
                        Text(message)
                            .accessibilityIdentifier("support.message")
                    }
                }
            }
            .navigationTitle("Support development")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("support.done")
                }
            }
            .task { await store.load() }
            .accessibilityIdentifier("support.screen")
        }
    }
}
