import SwiftUI

/// Record a fare seen elsewhere. Keeps the archive complete on days you'd
/// rather not spend an API search, and lets you backfill prices you already
/// know about.
struct LogPriceView: View {
    @Environment(TrackerStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let routeID: UUID

    @State private var priceText = ""
    @State private var airline = ""
    @State private var seenOn = Date.now

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Price") {
                        TextField("0", text: $priceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.body, design: .monospaced))
                    }
                    TextField("Airline (optional)", text: $airline)
                        .autocorrectionDisabled()
                    DatePicker(
                        "Seen on",
                        selection: $seenOn,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                } footer: {
                    Text("Use this for a fare you spotted on Google Flights or an airline site. It goes into the history exactly like an automatic check.")
                }
            }
            .navigationTitle("Log a price")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(price == nil)
                }
            }
        }
    }

    private var price: Decimal? {
        guard let value = Decimal(string: priceText), value > 0 else { return nil }
        return value
    }

    private func save() {
        guard let price else { return }
        store.logPrice(price, airline: airline, for: routeID, at: seenOn)
        dismiss()
    }
}
