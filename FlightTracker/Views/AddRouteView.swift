import SwiftUI

struct AddRouteView: View {
    @Environment(TrackerStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var origin = ""
    @State private var destination = ""
    @State private var departureDate = Date.now.addingTimeInterval(60 * 60 * 24 * 30)
    @State private var isRoundTrip = true
    @State private var returnDate = Date.now.addingTimeInterval(60 * 60 * 24 * 37)
    @State private var targetPriceText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Route") {
                    AirportField(title: "From", code: $origin)
                    AirportField(title: "To", code: $destination)
                }

                Section("Dates") {
                    DatePicker("Depart", selection: $departureDate, displayedComponents: .date)
                    Toggle("Round trip", isOn: $isRoundTrip.animation())
                    if isRoundTrip {
                        DatePicker(
                            "Return",
                            selection: $returnDate,
                            in: departureDate...,
                            displayedComponents: .date
                        )
                    }
                }

                Section {
                    TextField("e.g. 250", text: $targetPriceText)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Alert me under")
                } footer: {
                    Text("Optional. Fares at or below this price are highlighted in green.")
                }
            }
            .navigationTitle("Track a Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Track", action: save).disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        origin.count == 3 && destination.count == 3 && origin != destination
    }

    private func save() {
        let route = TrackedRoute(
            origin: origin,
            destination: destination,
            departureDate: departureDate,
            returnDate: isRoundTrip ? returnDate : nil,
            targetPrice: Decimal(string: targetPriceText)
        )
        store.add(route)
        dismiss()
    }
}

/// Three-letter airport code entry, uppercased and length-capped as you type.
private struct AirportField: View {
    let title: String
    @Binding var code: String

    var body: some View {
        LabeledContent(title) {
            TextField("SFO", text: $code)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .multilineTextAlignment(.trailing)
                .onChange(of: code) { _, newValue in
                    let filtered = newValue.uppercased().filter(\.isLetter)
                    code = String(filtered.prefix(3))
                }
        }
    }
}

#Preview {
    AddRouteView().environment(TrackerStore())
}
