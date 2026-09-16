# Fare Watch

An iPhone app for tracking flight prices on routes you care about. Add a trip,
give it a target price, and the app records every fare check so you can see
whether the price is trending your way.

Built with SwiftUI, Swift Charts, and the `@Observable` macro. iOS 17+.

## Running it

1. Open `FlightTracker.xcodeproj` in Xcode 16 or later.
2. Select the **FlightTracker** scheme and an iPhone simulator (or your device).
3. Press ⌘R.

To run on a physical iPhone, set your own team under *Signing & Capabilities*
and change the bundle identifier from `com.example.FlightTracker` to something
unique to you.

## What it does

- **Track routes** — origin/destination airport codes, departure date, optional
  return date, and an optional target price.
- **Check real fares** — live Google Flights prices via SerpAPI, or simulated
  fares with no key. Pull to refresh the list, or check one route at a time.
- **Build an archive** — every check is recorded. This is the part Google
  Flights won't do for you: it alerts on changes but never shows you the curve,
  and the data is gone when you stop tracking.
- **Read the trend** — once a route has three checks, the detail screen reports
  where today's fare sits in its own observed range, which way it's moving, and
  the low/average/high you've personally seen.
- **Log prices by hand** — spotted a fare somewhere else? Record it without
  spending an API search. Backfilled prices join the history like any other.
- **Set a real threshold** — a target price, not "prices are currently low".
  Fares at or below it are flagged, and a local notification fires on a new low.
- **Own your data** — routes and history live as JSON on the device, and export
  to CSV whenever you want it elsewhere.

## Fare data

### Live prices (SerpAPI)

`SerpAPIPriceProvider` pulls real Google Flights fares through SerpAPI's
`google_flights` engine — the number Google actually shows a traveller, not a
cached aggregate.

1. Sign up at [serpapi.com](https://serpapi.com) and copy your API key.
2. Open the app → **Settings** (gear, top left).
3. Set the fare source to **Live**, paste the key, tap **Save key**.

The key is stored in the iOS Keychain and is sent only to SerpAPI. Until a key
is entered, the app quietly falls back to simulated fares and says so in a
banner under the list, so an unset key never looks like real data.

**Quota.** Free SerpAPI accounts include roughly 100–250 searches a month. Each
route check spends exactly one. Three routes checked once a day is about 90 a
month, which fits; checking hourly does not. Once a day is the right cadence
anyway — fares don't move meaningfully faster than that. Log prices by hand on
days you'd rather not spend a search.

Google shut down its own fare API (QPX Express) in 2018 and has not replaced it,
which is why a scraping intermediary is the practical route to live prices.

### Simulated prices

`SimulatedPriceProvider` generates plausible fares offline: a stable base price
derived from the route, discounted by how far out the departure is, then
drifting a few percent on each check. It keeps the app fully runnable with no
key and burns no quota.

### Any other source

Conform to `PriceProvider`:

```swift
struct MyFareAPI: PriceProvider {
    func latestQuote(for route: TrackedRoute) async throws -> PriceQuote {
        // call your fare API, return the cheapest result
    }
}
```

and hand it to the store:

```swift
store.useProvider(MyFareAPI())
```

Nothing else changes — views, persistence, insights, and price-drop alerts all
work off whatever quotes the provider returns.

## Layout

```
FlightTracker/
├── FlightTrackerApp.swift        app entry point
├── Models/
│   ├── TrackedRoute.swift        TrackedRoute + PriceQuote
│   └── RouteInsights.swift       range position, trend, verdict
├── Services/
│   ├── PriceProvider.swift       the protocol every fare source implements
│   ├── SerpAPIPriceProvider.swift  live Google Flights fares
│   ├── SimulatedPriceProvider.swift
│   └── NotificationService.swift local price-drop notifications
├── Store/
│   ├── TrackerStore.swift        state, JSON persistence, refresh, CSV export
│   ├── FareSource.swift          live/simulated preference + provider factory
│   └── KeychainStore.swift       API key storage
└── Views/
    ├── RouteListView.swift       tracked routes, pull to refresh, source banner
    ├── AddRouteView.swift        add-a-route form
    ├── RouteDetailView.swift     current price, insights, trip info, log
    ├── InsightsCard.swift        where this fare sits in its own range
    ├── PriceHistoryChart.swift   Swift Charts price trend
    ├── LogPriceView.swift        record a fare seen elsewhere
    └── SettingsView.swift        fare source, API key, export
```

## Notes

The project uses Xcode 16 file-system-synchronized groups, so new `.swift`
files added anywhere under `FlightTracker/` are picked up automatically — no
need to edit the project file.
