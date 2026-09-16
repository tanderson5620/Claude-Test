import Foundation
import Observation

/// Owns the tracked routes, persists them to disk, and refreshes prices.
@MainActor
@Observable
final class TrackerStore {
    private(set) var routes: [TrackedRoute] = []
    private(set) var refreshingRouteIDs: Set<UUID> = []
    var errorMessage: String?

    private var provider: PriceProvider
    private let fileURL: URL

    var isRefreshing: Bool { !refreshingRouteIDs.isEmpty }

    init(
        provider: PriceProvider = SimulatedPriceProvider(),
        fileURL: URL = TrackerStore.defaultFileURL
    ) {
        self.provider = provider
        self.fileURL = fileURL
        load()
    }

    /// Swap the fare source at runtime, e.g. after the user enters an API key.
    func useProvider(_ provider: PriceProvider) {
        self.provider = provider
    }

    // MARK: - Editing

    func add(_ route: TrackedRoute) {
        routes.append(route)
        save()
        Task { await refresh(route.id) }
    }

    func update(_ route: TrackedRoute) {
        guard let index = routes.firstIndex(where: { $0.id == route.id }) else { return }
        routes[index] = route
        save()
    }

    func delete(at offsets: IndexSet) {
        routes.remove(atOffsets: offsets)
        save()
    }

    func route(withID id: UUID) -> TrackedRoute? {
        routes.first { $0.id == id }
    }

    /// Record a fare the user saw somewhere else (Google Flights, an airline
    /// site) so the history stays complete without spending an API search.
    func logPrice(_ price: Decimal, airline: String, for routeID: UUID, at date: Date = .now) {
        guard let index = routes.firstIndex(where: { $0.id == routeID }) else { return }
        let trimmed = airline.trimmingCharacters(in: .whitespaces)
        routes[index].quotes.append(
            PriceQuote(
                price: price,
                airline: trimmed.isEmpty ? "Logged by hand" : trimmed,
                checkedAt: date
            )
        )
        routes[index].quotes.sort { $0.checkedAt < $1.checkedAt }
        save()
    }

    /// Everything tracked, as CSV, so the archive is yours to keep.
    func exportCSV() -> String {
        var lines = ["route,depart,return,checked_at,price,currency,airline"]
        let stamp = ISO8601DateFormatter()
        let day = DateFormatter()
        day.locale = Locale(identifier: "en_US_POSIX")
        day.dateFormat = "yyyy-MM-dd"

        for route in routes {
            for quote in route.quotes.sorted(by: { $0.checkedAt < $1.checkedAt }) {
                lines.append([
                    "\(route.origin)-\(route.destination)",
                    day.string(from: route.departureDate),
                    route.returnDate.map(day.string(from:)) ?? "",
                    stamp.string(from: quote.checkedAt),
                    "\(quote.price)",
                    route.currencyCode,
                    quote.airline.replacingOccurrences(of: ",", with: " ")
                ].joined(separator: ","))
            }
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Price refresh

    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            for route in routes {
                group.addTask { @MainActor in await self.refresh(route.id) }
            }
        }
    }

    func refresh(_ routeID: UUID) async {
        guard let route = route(withID: routeID) else { return }
        refreshingRouteIDs.insert(routeID)
        defer { refreshingRouteIDs.remove(routeID) }

        do {
            let quote = try await provider.latestQuote(for: route)
            guard let index = routes.firstIndex(where: { $0.id == routeID }) else { return }

            let previousLow = routes[index].lowestQuote?.price
            routes[index].quotes.append(quote)
            save()

            if let previousLow, quote.price < previousLow {
                NotificationService.shared.notifyPriceDrop(
                    route: routes[index],
                    newPrice: quote.price
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Persistence

    static var defaultFileURL: URL {
        let directory = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "tracked-routes.json")
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        routes = (try? decoder.decode([TrackedRoute].self, from: data)) ?? []
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(routes)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            errorMessage = "Could not save your routes: \(error.localizedDescription)"
        }
    }
}
