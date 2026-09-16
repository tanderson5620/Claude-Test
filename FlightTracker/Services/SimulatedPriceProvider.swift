import Foundation

/// Offline fare source. Prices are derived deterministically from the route so
/// a given trip always starts at a believable number, then drift on each check
/// the way real fares do. Replace with a live API when you have credentials.
struct SimulatedPriceProvider: PriceProvider {
    private static let airlines = [
        "Alaska", "American", "Delta", "JetBlue", "Southwest", "United"
    ]

    func latestQuote(for route: TrackedRoute) async throws -> PriceQuote {
        // Pretend to hit the network so the UI's loading state is exercised.
        try? await Task.sleep(for: .milliseconds(600))

        let base = Self.basePrice(for: route)
        let drift = Double.random(in: -0.12...0.10)
        let price = max(59, base * (1 + drift))

        var seed = Hasher()
        seed.combine(route.origin)
        seed.combine(route.destination)
        let airline = Self.airlines[abs(seed.finalize()) % Self.airlines.count]

        return PriceQuote(
            price: Decimal(Int(price.rounded())),
            airline: airline,
            checkedAt: .now
        )
    }

    /// A stable starting fare: longer lead times and one-way trips are cheaper.
    private static func basePrice(for route: TrackedRoute) -> Double {
        var hasher = Hasher()
        hasher.combine(route.origin)
        hasher.combine(route.destination)
        let spread = Double(abs(hasher.finalize()) % 260)

        let daysOut = max(0, Calendar.current.dateComponents(
            [.day], from: .now, to: route.departureDate
        ).day ?? 0)
        let leadTimeDiscount = min(Double(daysOut), 120) * 0.9

        let roundTripMultiplier = route.isRoundTrip ? 1.85 : 1.0
        return (180 + spread - leadTimeDiscount) * roundTripMultiplier
    }
}
