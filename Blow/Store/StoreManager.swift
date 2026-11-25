import StoreKit
import SwiftUI

/// Membership tiers. Pro is a one-time purchase (kept for existing owners);
/// VIP is a yearly/monthly auto-renewing subscription for the birthday-keeper
/// features (unlimited presets, reminders, custom stickers).
enum Tier: Int, Comparable {
    case free = 0, pro = 1, vip = 2
    static func < (a: Tier, b: Tier) -> Bool { a.rawValue < b.rawValue }
}

/// One-time "Blow Pro" unlock plus the newer "Blow VIP" subscription.
/// Create these product IDs in App Store Connect (Pro = non-consumable,
/// VIP = auto-renewing subscription in one group).
@MainActor
@Observable
final class StoreManager {
    static let proID = "app.blow.pro"
    static let vipYearID = "app.blow.vip.year"
    static let vipMonthID = "app.blow.vip.month"

    private(set) var tier: Tier = .free
    private(set) var product: Product?          // Pro
    private(set) var vipProducts: [Product] = []
    private(set) var isPurchasing = false
    var lastError: String?

    /// Kept so all existing `isPro` checks keep working unchanged.
    var isPro: Bool { tier >= .pro }
    var isVIP: Bool { tier >= .vip }

    @ObservationIgnored private var updates: Task<Void, Never>?

    init() {
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let t) = result {
                    await t.finish()
                    await self?.refresh()
                }
            }
        }
        Task { [weak self] in
            await self?.loadProducts()
            await self?.refresh()
        }
    }

    var priceText: String { product?.displayPrice ?? "" }
    var vipYear: Product? { vipProducts.first { $0.id == Self.vipYearID } }
    var vipMonth: Product? { vipProducts.first { $0.id == Self.vipMonthID } }

    func loadProducts() async {
        let all = try? await Product.products(for: [Self.proID, Self.vipYearID, Self.vipMonthID])
        product = all?.first { $0.id == Self.proID }
        vipProducts = all?.filter { $0.id != Self.proID } ?? []
    }

    func refresh() async {
        var highest = Tier.free
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result, t.revocationDate == nil else { continue }
            switch t.productID {
            case Self.proID: highest = max(highest, .pro)
            case Self.vipYearID, Self.vipMonthID: highest = max(highest, .vip)
            default: break
            }
        }
        tier = highest
    }

    func purchase() async {
        guard let product else { lastError = "The store isn't available right now."; return }
        await buy(product)
    }

    func purchaseVIP(year: Bool) async {
        guard let target = year ? vipYear : vipMonth else {
            lastError = "The subscription isn't available right now."
            return
        }
        await buy(target)
    }

    private func buy(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            if case .success(let verification) = result, case .verified(let t) = verification {
                await t.finish()
                await refresh()
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }

    #if DEBUG
    func debugUnlock() { tier = .pro }
    func debugUnlockVIP() { tier = .vip }
    func debugLock() { tier = .free }
    #endif
}

struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 26) {
            Capsule().fill(Color.white.opacity(0.15)).frame(width: 36, height: 5).padding(.top, 10)
            Spacer(minLength: 0)
            Text("✦").font(.system(size: 34)).foregroundStyle(Theme.glow)
            Text(store.isVIP ? "Blow VIP" : "Blow Pro")
                .font(Theme.serif(36, weight: .medium))
                .foregroundStyle(Theme.cream)

            // VIP subscription card
            VStack(alignment: .leading, spacing: 12) {
                Text("VIP · Birthday keeper").font(Theme.serif(19, weight: .medium)).foregroundStyle(Theme.glow)
                feature("Everything in Pro")
                feature("Save up to 30 cake presets")
                feature("Scheduled birthday reminders, one-tap delivery")
                feature("Use your own photos as stickers")
                Button {
                    Task { await store.purchaseVIP(year: true); if store.isVIP { dismiss() } }
                } label: {
                    Text(store.isPurchasing ? "…" : "Subscribe VIP \(store.vipYear?.displayPrice ?? "")/year")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Theme.glow.opacity(0.85)))
                        .foregroundStyle(Theme.ink)
                }
                .disabled(store.isPurchasing || store.isVIP)
                if let month = store.vipMonth {
                    Button { Task { await store.purchaseVIP(year: false); if store.isVIP { dismiss() } } } label: {
                        Text("or \(month.displayPrice)/month").font(.footnote).foregroundStyle(Theme.muted)
                    }
                    .disabled(store.isPurchasing || store.isVIP)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))

            // Pro one-time card
            VStack(alignment: .leading, spacing: 12) {
                Text("Pro · One-time purchase").font(Theme.serif(19, weight: .medium)).foregroundStyle(Theme.cream)
                feature("The signature and occasion cakes")
                feature("The song in five languages")
                feature("Gold-leaf and star cake toppers")
                feature("Memory cards without the mark")
                feature("Yours forever — one purchase, no subscription")
                Button {
                    Task { await store.purchase(); if store.isPro { dismiss() } }
                } label: {
                    Text(store.isPurchasing ? "…" : "Unlock \(store.priceText)")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Theme.paper))
                        .foregroundStyle(Theme.ink)
                }
                .disabled(store.isPurchasing || store.isPro)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))

            HStack(spacing: 24) {
                Button("Restore") { Task { await store.restore(); if store.isPro { dismiss() } } }
                #if DEBUG
                Button("Pro") { store.debugUnlock(); dismiss() }
                Button("VIP") { store.debugUnlockVIP(); dismiss() }
                #endif
            }
            .font(.footnote)
            .foregroundStyle(Theme.muted)
            if let error = store.lastError {
                Text(error).font(.footnote).foregroundStyle(.red.opacity(0.8))
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.night.ignoresSafeArea())
    }

    private func feature(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "flame").foregroundStyle(Theme.wax)
            Text(text).foregroundStyle(Theme.cream.opacity(0.9))
        }
        .font(Theme.serif(17))
    }
}
