import Foundation

/// A route the user is watching, plus every price we have observed for it.
struct TrackedRoute: Identifiable, Codable, Hashable {
    let id: UUID
    var origin: String
    var destination: String
    var departureDate: Date
    var returnDate: Date?
    var targetPrice: Decimal?
    var currencyCode: String
    var quotes: [PriceQuote]

    init(
        id: UUID = UUID(),
        origin: String,
        destination: String,
        departureDate: Date,
        returnDate: Date? = nil,
        targetPrice: Decimal? = nil,
        currencyCode: String = Locale.current.currency?.identifier ?? "USD",
        quotes: [PriceQuote] = []
    ) {
        self.id = id
        self.origin = origin.uppercased()
        self.destination = destination.uppercased()
        self.departureDate = departureDate
        self.returnDate = returnDate
        self.targetPrice = targetPrice
        self.currencyCode = currencyCode
        self.quotes = quotes
    }

    var isRoundTrip: Bool { returnDate != nil }

    var latestQuote: PriceQuote? {
        quotes.max(by: { $0.checkedAt < $1.checkedAt })
    }

    var previousQuote: PriceQuote? {
        quotes.sorted(by: { $0.checkedAt < $1.checkedAt }).dropLast().last
    }

    var lowestQuote: PriceQuote? {
        quotes.min(by: { $0.price < $1.price })
    }

    /// Price movement since the previous check, if we have two data points.
    var change: Decimal? {
        guard let latest = latestQuote, let previous = previousQuote else { return nil }
        return latest.price - previous.price
    }

    var isAtOrBelowTarget: Bool {
        guard let target = targetPrice, let latest = latestQuote else { return false }
        return latest.price <= target
    }
}

/// One observed price for a route at a point in time.
struct PriceQuote: Identifiable, Codable, Hashable {
    let id: UUID
    var price: Decimal
    var airline: String
    var checkedAt: Date

    init(id: UUID = UUID(), price: Decimal, airline: String, checkedAt: Date = .now) {
        self.id = id
        self.price = price
        self.airline = airline
        self.checkedAt = checkedAt
    }
}
