import Foundation

/// Source of fare quotes. Swap in a real fare API by conforming to this
/// protocol and handing the implementation to `TrackerStore`.
protocol PriceProvider: Sendable {
    func latestQuote(for route: TrackedRoute) async throws -> PriceQuote
}

enum PriceProviderError: LocalizedError {
    case noFaresFound
    case network(String)

    var errorDescription: String? {
        switch self {
        case .noFaresFound:
            return "No fares were found for that route and date."
        case .network(let detail):
            return "Could not reach the fare service: \(detail)"
        }
    }
}
