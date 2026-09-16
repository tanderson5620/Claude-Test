import SwiftUI

/// The payoff for keeping your own archive: where today's fare sits in the
/// range you've personally observed on this route.
struct InsightsCard: View {
    let route: TrackedRoute
    let insights: RouteInsights

    private var code: String { route.currencyCode }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: insights.trend.symbolName)
                    .font(.subheadline.weight(.semibold))
                Text(insights.trend.label)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(insights.sampleCount) checks · \(insights.daysTracked)d")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .foregroundStyle(trendColor)

            Text(insights.verdict)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            rangeBar

            HStack {
                stat("Low", insights.low, .green)
                Divider().frame(height: 30)
                stat("Average", insights.average, .secondary)
                Divider().frame(height: 30)
                stat("High", insights.high, .red)
            }
        }
        .padding(.vertical, 4)
    }

    /// Current fare plotted against the observed low–high span.
    private var rangeBar: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let x = width * CGFloat(insights.positionInRange.clamped(to: 0...1))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.35), .yellow.opacity(0.3), .red.opacity(0.35)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 8)

                Circle()
                    .fill(Color.primary)
                    .frame(width: 13, height: 13)
                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2.5))
                    .offset(x: min(max(x - 6.5, 0), width - 13))
            }
            .frame(height: 13)
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 18)
        .accessibilityLabel("Current fare sits at \(Int(insights.positionInRange * 100)) percent of its observed range")
    }

    private func stat(_ label: String, _ value: Decimal, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .kerning(0.5)
            Text(value.formatted(.currency(code: code).precision(.fractionLength(0))))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint == .secondary ? .primary : tint)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trendColor: Color {
        switch insights.trend {
        case .falling: return .green
        case .rising: return .red
        case .steady: return .secondary
        }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
