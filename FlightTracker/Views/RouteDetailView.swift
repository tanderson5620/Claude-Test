import SwiftUI

struct RouteDetailView: View {
    @Environment(TrackerStore.self) private var store
    let routeID: UUID

    @State private var isLoggingPrice = false

    var body: some View {
        if let route = store.route(withID: routeID) {
            List {
                Section {
                    currentPrice(for: route)
                }

                if let insights = route.insights {
                    Section("What your archive says") {
                        InsightsCard(route: route, insights: insights)
                    }
                }

                if route.quotes.count > 1 {
                    Section("Price history") {
                        PriceHistoryChart(route: route)
                            .frame(height: 200)
                            .padding(.vertical, 8)
                    }
                }

                Section("Trip") {
                    LabeledContent("Route", value: "\(route.origin) → \(route.destination)")
                    LabeledContent(
                        "Depart",
                        value: route.departureDate.formatted(date: .abbreviated, time: .omitted)
                    )
                    if let returnDate = route.returnDate {
                        LabeledContent(
                            "Return",
                            value: returnDate.formatted(date: .abbreviated, time: .omitted)
                        )
                    }
                    if let target = route.targetPrice {
                        LabeledContent(
                            "Alert under",
                            value: target.formatted(.currency(code: route.currencyCode))
                        )
                    }
                    if let lowest = route.lowestQuote {
                        LabeledContent(
                            "Lowest seen",
                            value: lowest.price.formatted(.currency(code: route.currencyCode))
                        )
                    }
                }

                Section("Checks") {
                    ForEach(route.quotes.sorted(by: { $0.checkedAt > $1.checkedAt })) { quote in
                        LabeledContent {
                            Text(quote.price.formatted(.currency(code: route.currencyCode)))
                        } label: {
                            VStack(alignment: .leading) {
                                Text(quote.airline)
                                Text(quote.checkedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("\(route.origin) → \(route.destination)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Check now", systemImage: "arrow.clockwise") {
                            Task { await store.refresh(routeID) }
                        }
                        .disabled(store.refreshingRouteIDs.contains(routeID))

                        Button("Log a price I saw", systemImage: "square.and.pencil") {
                            isLoggingPrice = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $isLoggingPrice) {
                LogPriceView(routeID: routeID)
            }
        } else {
            ContentUnavailableView(
                "Route removed",
                systemImage: "airplane.slash",
                description: Text("This route is no longer being tracked.")
            )
        }
    }

    @ViewBuilder
    private func currentPrice(for route: TrackedRoute) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let latest = route.latestQuote {
                Text(latest.price.formatted(.currency(code: route.currencyCode)))
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .foregroundStyle(route.isAtOrBelowTarget ? Color.green : Color.primary)
                HStack(spacing: 8) {
                    Text("on \(latest.airline)")
                    PriceChangeLabel(route: route)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            } else if store.refreshingRouteIDs.contains(routeID) {
                ProgressView("Checking fares…")
            } else {
                Text("No price yet")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}
