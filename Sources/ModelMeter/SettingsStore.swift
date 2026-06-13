import CoreGraphics
import Foundation

final class SettingsStore: @unchecked Sendable {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let codexHome = "codexHome"
        static let codexDataSource = "codexDataSource"
        static let sessionLimit = "sessionLimit"
        static let dailyLimit = "dailyLimit"
        static let weeklyLimit = "weeklyLimit"
        static let refreshInterval = "refreshInterval"
        static let notificationsEnabled = "notificationsEnabled"
        static let notificationThreshold = "notificationThreshold"
        static let menuBarMetric = "menuBarMetric"
        static let menuBarDisplayMode = "menuBarDisplayMode"
        static let menuBarIconMode = "menuBarIconMode"
        static let menuBarLabelStyle = "menuBarLabelStyle"
        static let menuBarFontSize = "menuBarFontSize"
        static let resetDisplayMode = "resetDisplayMode"
        static let showHistoryGraph = "showHistoryGraph"
        static let showCodexInHistoryGraph = "showCodexInHistoryGraph"
        static let showClaudeInHistoryGraph = "showClaudeInHistoryGraph"
        static let showGeminiInHistoryGraph = "showGeminiInHistoryGraph"
        static let shadeHistoryGraphArea = "shadeHistoryGraphArea"
        static let historyGraphPosition = "historyGraphPosition"
        static let claudeOrganizationID = "claudeOrganizationID"
        static let codexEnabled = "codexEnabled"
        static let claudeEnabled = "claudeEnabled"
        static let geminiEnabled = "geminiEnabled"
        static let showCodexInMenuBar = "showCodexInMenuBar"
        static let showClaudeInMenuBar = "showClaudeInMenuBar"
        static let showGeminiInMenuBar = "showGeminiInMenuBar"
        static let paceWarningsEnabled = "paceWarningsEnabled"
        static let providerStatusWarningsEnabled = "providerStatusWarningsEnabled"
        static let popoverWidth = "popoverWidth"
        static let popoverHeight = "popoverHeight"
    }

    var codexHome: String {
        get {
            defaults.string(forKey: Key.codexHome)
                ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex").path
        }
        set { defaults.set(newValue, forKey: Key.codexHome) }
    }

    var codexDataSource: CodexDataSource {
        get {
            guard let rawValue = defaults.string(forKey: Key.codexDataSource),
                  let source = CodexDataSource(rawValue: rawValue)
            else {
                return .liveOAuth
            }
            return source
        }
        set { defaults.set(newValue.rawValue, forKey: Key.codexDataSource) }
    }

    var codexEnabled: Bool {
        get { defaults.object(forKey: Key.codexEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.codexEnabled) }
    }

    var claudeEnabled: Bool {
        get { defaults.object(forKey: Key.claudeEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.claudeEnabled) }
    }

    var geminiEnabled: Bool {
        get { defaults.object(forKey: Key.geminiEnabled) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.geminiEnabled) }
    }

    var showCodexInMenuBar: Bool {
        get { defaults.object(forKey: Key.showCodexInMenuBar) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.showCodexInMenuBar) }
    }

    var showClaudeInMenuBar: Bool {
        get { defaults.object(forKey: Key.showClaudeInMenuBar) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.showClaudeInMenuBar) }
    }

    var showGeminiInMenuBar: Bool {
        get { defaults.object(forKey: Key.showGeminiInMenuBar) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.showGeminiInMenuBar) }
    }


    var paceWarningsEnabled: Bool {
        get { defaults.object(forKey: Key.paceWarningsEnabled) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.paceWarningsEnabled) }
    }

    var providerStatusWarningsEnabled: Bool {
        get { defaults.object(forKey: Key.providerStatusWarningsEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.providerStatusWarningsEnabled) }
    }

    var sessionLimit: Int {
        get { value(for: Key.sessionLimit, defaultValue: 200_000) }
        set { defaults.set(newValue, forKey: Key.sessionLimit) }
    }

    var dailyLimit: Int {
        get { value(for: Key.dailyLimit, defaultValue: 500_000) }
        set { defaults.set(newValue, forKey: Key.dailyLimit) }
    }

    var weeklyLimit: Int {
        get { value(for: Key.weeklyLimit, defaultValue: 2_000_000) }
        set { defaults.set(newValue, forKey: Key.weeklyLimit) }
    }

    var refreshInterval: Double {
        get {
            let stored = defaults.double(forKey: Key.refreshInterval)
            return stored > 0 ? stored : 30
        }
        set { defaults.set(newValue, forKey: Key.refreshInterval) }
    }

    var notificationsEnabled: Bool {
        get {
            defaults.object(forKey: Key.notificationsEnabled) as? Bool ?? true
        }
        set { defaults.set(newValue, forKey: Key.notificationsEnabled) }
    }

    var notificationThreshold: Double {
        get {
            let stored = defaults.double(forKey: Key.notificationThreshold)
            return stored > 0 ? stored : 0.85
        }
        set { defaults.set(newValue, forKey: Key.notificationThreshold) }
    }

    var menuBarMetric: MenuBarMetric {
        get {
            guard let rawValue = defaults.string(forKey: Key.menuBarMetric),
                  let metric = MenuBarMetric(rawValue: rawValue)
            else {
                return .fiveHourAvailable
            }
            return metric
        }
        set { defaults.set(newValue.rawValue, forKey: Key.menuBarMetric) }
    }

    var menuBarDisplayMode: MenuBarDisplayMode {
        get {
            guard let rawValue = defaults.string(forKey: Key.menuBarDisplayMode),
                  let mode = MenuBarDisplayMode(rawValue: rawValue)
            else {
                return .allProviders
            }
            return mode
        }
        set { defaults.set(newValue.rawValue, forKey: Key.menuBarDisplayMode) }
    }

    var menuBarIconMode: MenuBarIconMode {
        get {
            guard let rawValue = defaults.string(forKey: Key.menuBarIconMode),
                  let mode = MenuBarIconMode(rawValue: rawValue)
            else {
                return .statusIcon
            }
            return mode
        }
        set { defaults.set(newValue.rawValue, forKey: Key.menuBarIconMode) }
    }

    var menuBarLabelStyle: MenuBarLabelStyle {
        get {
            guard let rawValue = defaults.string(forKey: Key.menuBarLabelStyle),
                  let style = MenuBarLabelStyle(rawValue: rawValue)
            else {
                return .letters
            }
            return style
        }
        set { defaults.set(newValue.rawValue, forKey: Key.menuBarLabelStyle) }
    }

    var menuBarFontSize: MenuBarFontSize {
        get {
            guard let rawValue = defaults.string(forKey: Key.menuBarFontSize),
                  let size = MenuBarFontSize(rawValue: rawValue)
            else {
                return .small
            }
            return size
        }
        set { defaults.set(newValue.rawValue, forKey: Key.menuBarFontSize) }
    }

    var resetDisplayMode: ResetDisplayMode {
        get {
            guard let rawValue = defaults.string(forKey: Key.resetDisplayMode),
                  let mode = ResetDisplayMode(rawValue: rawValue)
            else {
                return .relative
            }
            return mode
        }
        set { defaults.set(newValue.rawValue, forKey: Key.resetDisplayMode) }
    }

    var showHistoryGraph: Bool {
        get { defaults.object(forKey: Key.showHistoryGraph) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.showHistoryGraph) }
    }

    var showCodexInHistoryGraph: Bool {
        get { defaults.object(forKey: Key.showCodexInHistoryGraph) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.showCodexInHistoryGraph) }
    }

    var showClaudeInHistoryGraph: Bool {
        get { defaults.object(forKey: Key.showClaudeInHistoryGraph) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.showClaudeInHistoryGraph) }
    }

    var showGeminiInHistoryGraph: Bool {
        get { defaults.object(forKey: Key.showGeminiInHistoryGraph) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.showGeminiInHistoryGraph) }
    }

    var shadeHistoryGraphArea: Bool {
        get { defaults.object(forKey: Key.shadeHistoryGraphArea) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.shadeHistoryGraphArea) }
    }

    var historyGraphPosition: HistoryGraphPosition {
        get {
            guard let rawValue = defaults.string(forKey: Key.historyGraphPosition),
                  let position = HistoryGraphPosition(rawValue: rawValue)
            else {
                return .top
            }
            return position
        }
        set { defaults.set(newValue.rawValue, forKey: Key.historyGraphPosition) }
    }

    var claudeOrganizationID: String {
        get { defaults.string(forKey: Key.claudeOrganizationID) ?? "" }
        set { defaults.set(newValue, forKey: Key.claudeOrganizationID) }
    }

    var popoverSize: CGSize? {
        get {
            let width = defaults.double(forKey: Key.popoverWidth)
            let height = defaults.double(forKey: Key.popoverHeight)
            guard width >= 360, height >= 420 else { return nil }
            return CGSize(width: width, height: height)
        }
        set {
            guard let newValue else {
                defaults.removeObject(forKey: Key.popoverWidth)
                defaults.removeObject(forKey: Key.popoverHeight)
                return
            }
            defaults.set(newValue.width, forKey: Key.popoverWidth)
            defaults.set(newValue.height, forKey: Key.popoverHeight)
        }
    }

    private func value(for key: String, defaultValue: Int) -> Int {
        let stored = defaults.integer(forKey: key)
        return stored > 0 ? stored : defaultValue
    }
}
