import SwiftUI

struct RouteListView: View {
    @Environment(TrackerStore.self) private var store
    @State private var isAddingRoute = false

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Group {
                if store.routes.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(store.routes) { route in
                            NavigationLink(value: route.id) {
                                RouteRow(route: route)
                            }
                        }
                        .onDelete { store.delete(at: $0) }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await store.refreshAll() }
                }
            }
            .navigationTitle("Fare Watch")
            .navigationDestination(for: UUID.self) { RouteDetailView(routeID: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Track a route", systemImage: "plus") {
                        isAddingRoute = true
                    }
                }
            }
            .sheet(isPresented: $isAddingRoute) {
                AddRouteView()
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { store.errorMessage != nil },
                    set: { if !$0 { store.errorMessage = nil } }
                ),
                presenting: store.errorMessage
            ) { _ in
                Button("OK", role: .cancel) { store.errorMessage = nil }
            } message: { Text($0) }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No routes yet", systemImage: "airplane.departure")
        } description: {
            Text("Add a trip you're thinking about and Fare Watch will keep an eye on the price.")
        } actions: {
            Button("Track a route") { isAddingRoute = true }
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct RouteRow: View {
    @Environment(TrackerStore.self) private var store
    let route: TrackedRoute

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(route.origin) → \(route.destination)")
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if store.refreshingRouteIDs.contains(route.id) {
                ProgressView()
            } else if let latest = route.latestQuote {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(latest.price.formatted(.currency(code: route.currencyCode)))
                        .font(.headline)
                        .foregroundStyle(route.isAtOrBelowTarget ? Color.green : Color.primary)
                    PriceChangeLabel(route: route)
                }
            } else {
                Text("—").foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var subtitle: String {
        let departure = route.departureDate.formatted(.dateTime.month(.abbreviated).day())
        guard let returnDate = route.returnDate else { return "\(departure) · one way" }
        return "\(departure) – \(returnDate.formatted(.dateTime.month(.abbreviated).day()))"
    }
}

struct PriceChangeLabel: View {
    let route: TrackedRoute

    var body: some View {
        if let change = route.change, change != 0 {
            let isDrop = change < 0
            Label(
                abs(change).formatted(.currency(code: route.currencyCode)),
                systemImage: isDrop ? "arrow.down.right" : "arrow.up.right"
            )
            .font(.caption)
            .foregroundStyle(isDrop ? Color.green : Color.red)
        } else {
            Text("no change")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    RouteListView().environment(TrackerStore())
}
