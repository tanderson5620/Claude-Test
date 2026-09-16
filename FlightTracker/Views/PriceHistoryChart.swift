import Charts
import SwiftUI

/// Line-and-point chart of every price we have recorded for a route, with the
/// target price drawn in as a dashed rule when the user set one.
struct PriceHistoryChart: View {
    let route: TrackedRoute

    private var quotes: [PriceQuote] {
        route.quotes.sorted(by: { $0.checkedAt < $1.checkedAt })
    }

    var body: some View {
        Chart {
            ForEach(quotes) { quote in
                LineMark(
                    x: .value("Checked", quote.checkedAt),
                    y: .value("Price", (quote.price as NSDecimalNumber).doubleValue)
                )
                .interpolationMethod(.monotone)

                PointMark(
                    x: .value("Checked", quote.checkedAt),
                    y: .value("Price", (quote.price as NSDecimalNumber).doubleValue)
                )
                .symbolSize(28)
            }

            if let target = route.targetPrice {
                RuleMark(y: .value("Target", (target as NSDecimalNumber).doubleValue))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.green)
                    .annotation(position: .top, alignment: .leading) {
                        Text("Target")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
    }
}
