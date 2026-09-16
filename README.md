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
- **Check fares** — pull to refresh the whole list, or *Check now* on a single
  route. Every check is appended to that route's history.
- **See the trend** — a Swift Charts line chart of all recorded prices, with
  your target drawn in as a dashed rule.
- **Get told about drops** — a local notification fires when a check comes back
  below the lowest price seen so far.
- **Keep your data** — routes and their price history are stored as JSON in the
  app's Application Support directory. Nothing leaves the device.

## Fare data

The app ships with `SimulatedPriceProvider`, which generates plausible fares
offline: a stable base price derived from the route, discounted by how far out
the departure is, then drifting a few percent on each check. This keeps the app
fully runnable without an API key.

To use real fares, conform to the `PriceProvider` protocol:

```swift
struct MyFareAPI: PriceProvider {
    func latestQuote(for route: TrackedRoute) async throws -> PriceQuote {
        // call your fare API, return the cheapest result
    }
}
```

and hand it to the store in `FlightTrackerApp.swift`:

```swift
@State private var store = TrackerStore(provider: MyFareAPI())
```

Nothing else needs to change — the views, persistence, and price-drop alerts
all work off whatever quotes the provider returns.

## Layout

```
FlightTracker/
├── FlightTrackerApp.swift        app entry point
├── Models/TrackedRoute.swift     TrackedRoute + PriceQuote
├── Services/
│   ├── PriceProvider.swift       the protocol to implement for live fares
│   ├── SimulatedPriceProvider.swift
│   └── NotificationService.swift local price-drop notifications
├── Store/TrackerStore.swift      state, JSON persistence, refresh logic
└── Views/
    ├── RouteListView.swift       tracked routes, pull to refresh
    ├── AddRouteView.swift        add-a-route form
    ├── RouteDetailView.swift     current price, trip info, check history
    └── PriceHistoryChart.swift   Swift Charts price trend
```

## Notes

The project uses Xcode 16 file-system-synchronized groups, so new `.swift`
files added anywhere under `FlightTracker/` are picked up automatically — no
need to edit the project file.
