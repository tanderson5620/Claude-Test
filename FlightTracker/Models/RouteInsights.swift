import Foundation

/// What the archive tells you that a single lookup can't: where the current
/// fare sits in its own history, which way it's moving, and whether waiting has
/// been paying off on this route.
struct RouteInsights {
    let sampleCount: Int
    let low: Decimal
    let high: Decimal
    let average: Decimal
    let current: Decimal
    /// 0 = at the lowest fare ever seen, 1 = at the highest.
    let positionInRange: Double
    let trend: Trend
    let daysTracked: Int

    enum Trend {
        case falling, rising, steady

        var label: String {
            switch self {
            case .falling: return "Trending down"
            case .rising: return "Trending up"
            case .steady: return "Holding steady"
            }
        }

        var symbolName: String {
            switch self {
            case .falling: return "arrow.down.right"
            case .rising: return "arrow.up.right"
            case .steady: return "arrow.right"
            }
        }
    }

    /// A plain-language read on the current fare.
    var verdict: String {
        switch positionInRange {
        case ..<0.15: return "This is about as low as you've seen it."
        case ..<0.4: return "On the cheap side of its range."
        case ..<0.6: return "Middle of its usual range."
        case ..<0.85: return "On the expensive side of its range."
        default: return "Near the top of its range — worth waiting if you can."
        }
    }
}

extension TrackedRoute {
    /// Needs at least three checks before the numbers mean anything.
    var insights: RouteInsights? {
        guard quotes.count >= 3, let current = latestQuote?.price else { return nil }

        let ordered = quotes.sorted { $0.checkedAt < $1.checkedAt }
        let prices = ordered.map(\.price)
        let low = prices.min()!
        let high = prices.max()!
        let total = prices.reduce(Decimal(0), +)
        let average = total / Decimal(prices.count)

        let lowValue = (low as NSDecimalNumber).doubleValue
        let highValue = (high as NSDecimalNumber).doubleValue
        let currentValue = (current as NSDecimalNumber).doubleValue
        let span = highValue - lowValue
        let position = span > 0 ? (currentValue - lowValue) / span : 0

        // Compare the recent third against the earliest third; a 3% move either
        // way is the threshold for calling a direction.
        let window = max(1, ordered.count / 3)
        let early = mean(ordered.prefix(window).map(\.price))
        let recent = mean(ordered.suffix(window).map(\.price))
        let shift = early > 0 ? (recent - early) / early : 0

        let trend: RouteInsights.Trend
        if shift < -0.03 {
            trend = .falling
        } else if shift > 0.03 {
            trend = .rising
        } else {
            trend = .steady
        }

        let days = Calendar.current.dateComponents(
            [.day], from: ordered.first!.checkedAt, to: ordered.last!.checkedAt
        ).day ?? 0

        return RouteInsights(
            sampleCount: ordered.count,
            low: low,
            high: high,
            average: average,
            current: current,
            positionInRange: position,
            trend: trend,
            daysTracked: max(days, 0)
        )
    }

    private func mean(_ values: [Decimal]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sum = values.reduce(Decimal(0), +) / Decimal(values.count)
        return (sum as NSDecimalNumber).doubleValue
    }
}
