import Foundation

/// Where fares come from. The app ships usable without credentials and upgrades
/// to live Google Flights data once a SerpAPI key is entered.
enum FareSource: String, CaseIterable, Identifiable {
    case live
    case simulated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .live: return "Live (SerpAPI)"
        case .simulated: return "Simulated"
        }
    }

    var detail: String {
        switch self {
        case .live:
            return "Real Google Flights fares. Uses one SerpAPI search per route per check."
        case .simulated:
            return "Plausible offline fares. No API key and no quota used."
        }
    }
}

/// User settings that outlive a launch. The API key itself lives in the
/// Keychain; only the non-secret preferences go in UserDefaults.
@MainActor
@Observable
final class Settings {
    private enum Keys {
        static let source = "fareSource"
        static let apiKeyAccount = "serpapi.key"
    }

    var source: FareSource {
        didSet { UserDefaults.standard.set(source.rawValue, forKey: Keys.source) }
    }

    var apiKey: String {
        didSet { KeychainStore.set(apiKey, for: Keys.apiKeyAccount) }
    }

    var hasKey: Bool { !apiKey.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Live data needs a key; without one we quietly fall back to simulated.
    var effectiveSource: FareSource {
        source == .live && hasKey ? .live : .simulated
    }

    init() {
        let stored = UserDefaults.standard.string(forKey: Keys.source)
        self.source = stored.flatMap(FareSource.init(rawValue:)) ?? .simulated
        self.apiKey = KeychainStore.string(for: Keys.apiKeyAccount) ?? ""
    }

    func makeProvider() -> PriceProvider {
        switch effectiveSource {
        case .live:
            return SerpAPIPriceProvider(apiKey: apiKey.trimmingCharacters(in: .whitespaces))
        case .simulated:
            return SimulatedPriceProvider()
        }
    }
}
