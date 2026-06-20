import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: UsageStore

    var body: some View {
        TabView {
            displayTab
                .tabItem { Label("Menu Bar", systemImage: "menubar.rectangle") }
            sourcesTab
                .tabItem { Label("Providers", systemImage: "server.rack") }
            graphTab
                .tabItem { Label("History", systemImage: "chart.line.uptrend.xyaxis") }
            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .padding(18)
        .onDisappear {
            store.saveSettings()
        }
    }

    private var displayTab: some View {
        Form {
            Section("Menu Bar Providers") {
                Toggle("Codex", isOn: $store.showCodexInMenuBar)
                    .disabled(!store.codexEnabled)
                Toggle("Claude", isOn: $store.showClaudeInMenuBar)
                    .disabled(!store.claudeEnabled)
                Toggle("Gemini", isOn: $store.showGeminiInMenuBar)
                    .disabled(!store.geminiEnabled)
                Text("Only visible providers appear in the menu bar. Collection is controlled in Sources.")
                    .settingsFootnote()
            }

            Section("Menu Bar Display") {
                Picker("Mode", selection: $store.menuBarDisplayMode) {
                    ForEach(MenuBarDisplayMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.menu)

                Picker("Metric", selection: $store.menuBarMetric) {
                    ForEach(MenuBarMetric.allCases) { metric in
                        Text(metric.title).tag(metric)
                    }
                }
                .pickerStyle(.menu)

                Picker("Provider Labels", selection: $store.menuBarLabelStyle) {
                    ForEach(MenuBarLabelStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Icon", selection: $store.menuBarIconMode) {
                    ForEach(MenuBarIconMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Font Size", selection: $store.menuBarFontSize) {
                    ForEach(MenuBarFontSize.allCases) { size in
                        Text(size.title).tag(size)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Reset Times", selection: $store.resetDisplayMode) {
                    ForEach(ResetDisplayMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text("Provider labels also control the graph legend.")
                    .settingsFootnote()
            }

            Section("Warnings") {
                Toggle("Usage pace", isOn: $store.paceWarningsEnabled)
                Toggle("Provider incidents", isOn: $store.providerStatusWarningsEnabled)
                HStack {
                    Text("Provider Status")
                    Spacer()
                    Button {
                        store.refreshProviderStatuses()
                    } label: {
                        Label("Refresh", systemImage: "waveform.path.ecg")
                    }
                    .disabled(!store.providerStatusWarningsEnabled)
                }
                Text("Pace warnings turn menu bar values red. Provider incidents explain whether a live reading may be less trustworthy.")
                    .settingsFootnote()
            }

            Section("Preview") {
                LabeledContent("Current menu bar", value: store.menuTitle)
            }
        }
        .formStyle(.grouped)
    }

    private var sourcesTab: some View {
        Form {
            Section("Codex") {
                Toggle("Enable Codex", isOn: $store.codexEnabled)
                Picker("Usage Source", selection: $store.codexDataSource) {
                    ForEach(CodexDataSource.allCases) { source in
                        Text(source.title).tag(source)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!store.codexEnabled)

                TextField("Codex home", text: $store.codexHome)
                    .disabled(!store.codexEnabled)
                LabeledContent("Current source", value: store.snapshot.rateLimits?.sourceLabel ?? "Not refreshed")

                if let error = store.snapshot.errorMessage, store.codexEnabled {
                    statusText(error)
                }

                Text("Live ChatGPT uses the existing Codex sign-in. Local files may be stale.")
                    .settingsFootnote()
            }

            Section("Claude") {
                Toggle("Enable Claude", isOn: $store.claudeEnabled)
                Button {
                    ClaudeSignInWindowManager.shared.open(store: store)
                } label: {
                    Label("Sign in with Claude", systemImage: "person.crop.circle.badge.checkmark")
                }
                .disabled(!store.claudeEnabled)

                TextField("Organization ID", text: $store.claudeOrganizationID)
                    .disabled(!store.claudeEnabled)
                SecureField("Session key", text: $store.claudeSessionKey)
                    .disabled(!store.claudeEnabled)

                Button {
                    store.resetClaudeCredentials()
                } label: {
                    Label("Reset Claude Credentials", systemImage: "key.slash")
                }
                .disabled(!store.claudeEnabled)

                if let error = store.claudeSnapshot.errorMessage, store.claudeEnabled, (!store.claudeOrganizationID.isEmpty || !store.claudeSessionKey.isEmpty) {
                    statusText(error)
                }

                Text("Claude credentials are kept in macOS Keychain.")
                    .settingsFootnote()
            }

            Section("Gemini") {
                Toggle("Enable Gemini", isOn: $store.geminiEnabled)
                LabeledContent("Web session") {
                    Label(geminiWebSessionText, systemImage: geminiWebSessionAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(geminiWebSessionAvailable ? .green : .orange)
                        .labelStyle(.titleAndIcon)
                }
                .disabled(!store.geminiEnabled)

                HStack {
                    Button {
                        GeminiSignInWindowManager.shared.open(store: store)
                    } label: {
                        Label("Sign in", systemImage: "person.crop.circle.badge.checkmark")
                    }
                    Button {
                        store.refreshGeminiNow()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    Button {
                        store.resetGeminiCredentials()
                    } label: {
                        Label("Reset", systemImage: "trash")
                    }
                }
                .disabled(!store.geminiEnabled)

                if let error = store.geminiSnapshot.errorMessage, store.geminiEnabled {
                    statusText(error)
                }

                Text("Gemini is read from its usage page through Model Meter's WebKit session.")
                    .settingsFootnote()
            }
        }
        .formStyle(.grouped)
    }

    private var graphTab: some View {
        Form {
            Section("Graph") {
                Toggle("Show graph", isOn: $store.showHistoryGraph)
                Picker("Position", selection: $store.historyGraphPosition) {
                    ForEach(HistoryGraphPosition.allCases) { position in
                        Text(position.title).tag(position)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!store.showHistoryGraph)
            }

            Section("Providers") {
                Toggle("Codex", isOn: $store.showCodexInHistoryGraph)
                    .disabled(!store.showHistoryGraph || !store.codexEnabled)
                Toggle("Claude", isOn: $store.showClaudeInHistoryGraph)
                    .disabled(!store.showHistoryGraph || !store.claudeEnabled)
                Toggle("Gemini", isOn: $store.showGeminiInHistoryGraph)
                    .disabled(!store.showHistoryGraph || !store.geminiEnabled)
                Text("Hidden providers are removed from the graph and legend only.")
                    .settingsFootnote()
            }

            Section("Style") {
                Toggle("Shade below lines", isOn: $store.shadeHistoryGraphArea)
                    .disabled(!store.showHistoryGraph)
                Text("Area fill works best when one provider is selected.")
                    .settingsFootnote()
            }
        }
        .formStyle(.grouped)
    }

    private var aboutTab: some View {
        Form {
            Section("Model Meter") {
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                Button {
                    checkForUpdates()
                } label: {
                    Label("Check for Updates", systemImage: "arrow.triangle.2.circlepath")
                }
            }

            Section("Support") {
                Button {
                    openFeedbackEmail(subject: "Model Meter feedback")
                } label: {
                    Label("Send Feedback", systemImage: "envelope")
                }
                Button {
                    openFeedbackEmail(subject: "Model Meter feature request")
                } label: {
                    Label("Request Feature", systemImage: "lightbulb")
                }
                Text("Opens your email app. Nothing is sent automatically.")
                    .settingsFootnote()
            }

            Section("Privacy") {
                Text("Usage percentages, reset times, and provider status are stored locally. Claude credentials use macOS Keychain. Gemini uses an embedded WebKit session.")
                    .settingsFootnote()
            }

            Section("Links") {
                Button { openDocument("PRIVACY") } label: {
                    Label("Privacy", systemImage: "lock.shield")
                }
                Button { openDocument("THIRD_PARTY_NOTICES") } label: {
                    Label("Licenses", systemImage: "doc.text")
                }
                Button { openURL("https://abokadolabs.com/") } label: {
                    Label("Website", systemImage: "globe")
                }
            }
        }
        .formStyle(.grouped)
    }

    private var geminiWebSessionAvailable: Bool {
        !store.geminiSnapshot.items.isEmpty || GeminiWebSession.hasStoredSnapshot
    }

    private var geminiWebSessionText: String {
        if let updatedAt = store.geminiSnapshot.updatedAt {
            return "Last captured \(updatedAt.formatted(date: .omitted, time: .shortened))"
        }
        return "Sign in required"
    }

    private func statusText(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.orange)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func checkForUpdates() {
        NSApp.sendAction(#selector(AppDelegate.checkForUpdates(_:)), to: nil, from: nil)
    }

    private func openDocument(_ name: String) {
        if let url = Bundle.main.url(forResource: name, withExtension: "md") {
            NSWorkspace.shared.open(url)
        } else {
            openURL("https://abokadolabs.com/")
        }
    }

    private func openFeedbackEmail(subject: String) {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let body = """
        App version: Model Meter \(version) (\(build))
        macOS version: \(osVersion)

        What happened / What would you like?


        Steps or context:


        Expected result:


        """
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "hello@abokadolabs.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        guard let url = components.url else { return }
        NSWorkspace.shared.open(url)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        NSWorkspace.shared.open(url)
    }
}

private extension Text {
    func settingsFootnote() -> some View {
        self
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
