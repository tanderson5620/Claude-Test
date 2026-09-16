import SwiftUI

struct SettingsView: View {
    @Environment(TrackerStore.self) private var store
    @Environment(Settings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var keyDraft = ""
    @State private var showingKey = false
    @State private var exportedCSV: String?

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                Section {
                    Picker("Fare source", selection: $settings.source) {
                        ForEach(FareSource.allCases) { source in
                            Text(source.title).tag(source)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(settings.source.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if settings.source == .live && !settings.hasKey {
                        Label(
                            "Add a key below — until then, checks use simulated fares.",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.footnote)
                        .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Where fares come from")
                }

                Section {
                    HStack {
                        Group {
                            if showingKey {
                                TextField("SerpAPI key", text: $keyDraft)
                            } else {
                                SecureField("SerpAPI key", text: $keyDraft)
                            }
                        }
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))

                        Button {
                            showingKey.toggle()
                        } label: {
                            Image(systemName: showingKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                    }

                    Button("Save key") {
                        settings.apiKey = keyDraft.trimmingCharacters(in: .whitespaces)
                        store.useProvider(settings.makeProvider())
                    }
                    .disabled(keyDraft.trimmingCharacters(in: .whitespaces) == settings.apiKey)

                    if settings.hasKey {
                        Button("Remove key", role: .destructive) {
                            keyDraft = ""
                            settings.apiKey = ""
                            store.useProvider(settings.makeProvider())
                        }
                    }
                } header: {
                    Text("SerpAPI key")
                } footer: {
                    Text("Stored in the iOS Keychain, never sent anywhere but SerpAPI. Free accounts include roughly 100–250 searches a month — one route checked once a day uses about 30.")
                }

                Section {
                    LabeledContent("Routes", value: "\(store.routes.count)")
                    LabeledContent("Prices recorded", value: "\(totalQuotes)")
                    Button("Export history as CSV") {
                        exportedCSV = store.exportCSV()
                    }
                } header: {
                    Text("Your archive")
                } footer: {
                    Text("Every fare you've recorded stays on this device. Export takes it with you.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { keyDraft = settings.apiKey }
            .sheet(isPresented: Binding(
                get: { exportedCSV != nil },
                set: { if !$0 { exportedCSV = nil } }
            )) {
                if let csv = exportedCSV {
                    ShareLink(item: csv, preview: SharePreview("fare-history.csv")) {
                        Label("Share fare-history.csv", systemImage: "square.and.arrow.up")
                    }
                    .padding()
                    .presentationDetents([.height(140)])
                }
            }
        }
    }

    private var totalQuotes: Int {
        store.routes.reduce(0) { $0 + $1.quotes.count }
    }
}
