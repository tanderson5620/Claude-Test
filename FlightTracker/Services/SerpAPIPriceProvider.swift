import Foundation

/// Live fares from Google Flights, by way of SerpAPI's `google_flights` engine.
///
/// SerpAPI runs the scraping infrastructure against Google Flights and returns
/// structured JSON, so this is the real number Google shows a traveller rather
/// than a cached aggregate. Free tier is on the order of 100–250 searches a
/// month, which covers a handful of routes checked once a day.
struct SerpAPIPriceProvider: PriceProvider {
    let apiKey: String
    var session: URLSession = .shared

    private static let endpoint = URL(string: "https://serpapi.com/search.json")!

    func latestQuote(for route: TrackedRoute) async throws -> PriceQuote {
        var components = URLComponents(url: Self.endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "engine", value: "google_flights"),
            URLQueryItem(name: "departure_id", value: route.origin),
            URLQueryItem(name: "arrival_id", value: route.destination),
            URLQueryItem(name: "outbound_date", value: Self.apiDate(route.departureDate)),
            // SerpAPI: 1 = round trip, 2 = one way.
            URLQueryItem(name: "type", value: route.isRoundTrip ? "1" : "2"),
            URLQueryItem(name: "currency", value: route.currencyCode),
            URLQueryItem(name: "hl", value: "en"),
            URLQueryItem(name: "api_key", value: apiKey)
        ]
        if let returnDate = route.returnDate {
            components.queryItems?.append(
                URLQueryItem(name: "return_date", value: Self.apiDate(returnDate))
            )
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: components.url!)
        } catch {
            throw PriceProviderError.network(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw Self.error(forStatus: http.statusCode, body: data)
        }

        let payload: SerpAPIResponse
        do {
            payload = try JSONDecoder().decode(SerpAPIResponse.self, from: data)
        } catch {
            throw PriceProviderError.network("Unexpected response from SerpAPI.")
        }

        if let message = payload.error {
            throw PriceProviderError.network(message)
        }

        // Google groups results into "best" and "other"; the cheapest across
        // both is what we track.
        let candidates = (payload.bestFlights ?? []) + (payload.otherFlights ?? [])
        guard let cheapest = candidates
            .filter({ $0.price != nil })
            .min(by: { ($0.price ?? .max) < ($1.price ?? .max) }),
            let price = cheapest.price
        else {
            throw PriceProviderError.noFaresFound
        }

        return PriceQuote(
            price: Decimal(price),
            airline: cheapest.primaryAirline,
            checkedAt: .now
        )
    }

    private static func apiDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// Turn SerpAPI's HTTP codes into something a traveller can act on.
    private static func error(forStatus status: Int, body: Data) -> PriceProviderError {
        if let payload = try? JSONDecoder().decode(SerpAPIResponse.self, from: body),
           let message = payload.error {
            return .network(message)
        }
        switch status {
        case 401:
            return .network("That API key was rejected. Check it in Settings.")
        case 429:
            return .network("You're out of SerpAPI searches for this month.")
        default:
            return .network("SerpAPI returned status \(status).")
        }
    }
}

// MARK: - Response shapes

private struct SerpAPIResponse: Decodable {
    let error: String?
    let bestFlights: [SerpAPIItinerary]?
    let otherFlights: [SerpAPIItinerary]?

    enum CodingKeys: String, CodingKey {
        case error
        case bestFlights = "best_flights"
        case otherFlights = "other_flights"
    }
}

private struct SerpAPIItinerary: Decodable {
    let price: Int?
    let flights: [SerpAPILeg]?

    /// The carrier on the first leg, which is how Google labels an itinerary.
    var primaryAirline: String {
        flights?.first?.airline ?? "Unknown"
    }
}

private struct SerpAPILeg: Decodable {
    let airline: String?
}
