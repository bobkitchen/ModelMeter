import Foundation
@testable import ModelMeter
import XCTest

final class UsageReaderTests: XCTestCase {
    func testSkipsZeroRateLimitPlaceholderAfterRealSnapshot() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("rollout-placeholder-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let real = #"{"timestamp":"2026-05-17T15:20:04.087Z","payload":{"type":"token_count","rate_limits":{"primary":{"used_percent":25,"window_minutes":300,"resets_at":1779032052},"secondary":{"used_percent":9,"window_minutes":10080,"resets_at":1779577219},"plan_type":"prolite"}}}"#
        let placeholder = #"{"timestamp":"2026-05-17T15:20:19.304Z","payload":{"type":"token_count","rate_limits":{"primary":{"used_percent":0,"window_minutes":300,"resets_at":1779049219},"secondary":{"used_percent":0,"window_minutes":10080,"resets_at":1779636019},"plan_type":"prolite"}}}"#
        try [real, placeholder].joined(separator: "\n").write(to: fileURL, atomically: true, encoding: .utf8)

        let rateLimits = UsageReader().loadRateLimitsForTesting(fileURL: fileURL)

        XCTAssertEqual(rateLimits?.primary.usedPercent, 25)
        XCTAssertEqual(rateLimits?.secondary.usedPercent, 9)
        XCTAssertEqual(rateLimits?.displayPlan, "prolite")
    }

    func testChoosesNewestRealSnapshotAcrossFilesBeforeNewerPlaceholder() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("codex-rate-limit-\(UUID().uuidString)", isDirectory: true)
        let sessions = directory.appendingPathComponent("sessions", isDirectory: true)
        try FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let realFile = sessions.appendingPathComponent("rollout-real.jsonl")
        let placeholderFile = sessions.appendingPathComponent("rollout-placeholder.jsonl")
        let real = #"{"timestamp":"2026-05-22T09:38:49.892Z","payload":{"type":"token_count"},"rate_limits":{"primary":{"used_percent":6,"window_minutes":300,"resets_at":1779451530},"secondary":{"used_percent":7,"window_minutes":10080,"resets_at":1779820514},"plan_type":"prolite"}}"#
        let placeholder = #"{"timestamp":"2026-05-22T09:42:44.091Z","payload":{"type":"token_count"},"rate_limits":{"primary":{"used_percent":0,"window_minutes":300,"resets_at":1779460943},"secondary":{"used_percent":0,"window_minutes":10080,"resets_at":1780047743}}}"#
        try real.write(to: realFile, atomically: true, encoding: .utf8)
        try placeholder.write(to: placeholderFile, atomically: true, encoding: .utf8)

        let snapshot = UsageReader().loadBalanceSnapshot(codexHome: directory.path)

        XCTAssertEqual(snapshot.rateLimits?.primary.usedPercent, 6)
        XCTAssertEqual(snapshot.rateLimits?.secondary.usedPercent, 7)
        XCTAssertEqual(snapshot.rateLimits?.displayPlan, "prolite")
    }

    func testKeepsRealZeroAfterWindowReset() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("rollout-real-zero-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let stalePreviousWindow = #"{"timestamp":"2026-05-17T15:31:17.476Z","payload":{"type":"token_count","rate_limits":{"primary":{"used_percent":26,"window_minutes":300,"resets_at":1779032051},"secondary":{"used_percent":9,"window_minutes":10080,"resets_at":1779577218},"plan_type":"prolite"}}}"#
        let currentWindow = #"{"timestamp":"2026-05-17T15:38:27.572Z","payload":{"type":"token_count","rate_limits":{"primary":{"used_percent":0,"window_minutes":300,"resets_at":1779050062},"secondary":{"used_percent":9,"window_minutes":10080,"resets_at":1779577221},"plan_type":"prolite"}}}"#
        try [stalePreviousWindow, currentWindow].joined(separator: "\n").write(to: fileURL, atomically: true, encoding: .utf8)

        let rateLimits = UsageReader().loadRateLimitsForTesting(fileURL: fileURL)

        XCTAssertEqual(rateLimits?.primary.usedPercent, 0)
        XCTAssertEqual(rateLimits?.secondary.usedPercent, 9)
        XCTAssertEqual(try XCTUnwrap(rateLimits?.primary.resetsAt).timeIntervalSince1970, 1_779_050_062, accuracy: 0.1)
    }

    func testGeminiParserReadsOnlyDocumentedUsageRows() throws {
        let renderedText = """
        Gemini
        Usage limits
        Current usage
        Used
        1%
        Available
        99%
        Resets Today at 6:00 PM
        Weekly limit
        Used 9%
        Available 91%
        Resets Thu 11:00 AM
        """

        let items = GeminiUsageParser.parse(renderedText)

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].id, "current-usage")
        XCTAssertEqual(items[0].title, "Current usage")
        XCTAssertEqual(items[0].usedPercent, 1)
        XCTAssertEqual(items[0].remainingPercent, 99)
        XCTAssertEqual(items[0].detail, "Resets Today at 6:00 PM")
        XCTAssertEqual(items[1].id, "weekly-limit")
        XCTAssertEqual(items[1].title, "Weekly limit")
        XCTAssertEqual(items[1].usedPercent, 9)
        XCTAssertEqual(items[1].remainingPercent, 91)
    }


    func testGeminiParserReadsCompactRenderedUsageText() throws {
        let renderedText = """
        URL: https://gemini.google.com/usage
        TITLE: Usage | Google Account: Bob Kitchen
        BODY INNER TEXT
        Gemini Usage limits PRO Your plan's limits determine how much you can use Gemini over time. Advanced models and features can take up more usage. Learn more Updated just now Current usage 0% used Resets at 3:28 AM Weekly limit Resets May 26 at 10:28 PM 0% used Get 20x more usage than AI Pro $199.99/month Upgrade
        DOM AND SHADOW TEXT
        window.WIZ_global_data = {percent: "92%"}
        SCRIPT CANDIDATES
        </script><!-- Google Tag Manager --> 92%
        """

        let items = GeminiUsageParser.parse(renderedText)

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].id, "current-usage")
        XCTAssertEqual(items[0].usedPercent, 0)
        XCTAssertEqual(items[0].remainingPercent, 100)
        XCTAssertEqual(items[0].detail, "Resets at 3:28 AM")
        XCTAssertEqual(items[1].id, "weekly-limit")
        XCTAssertEqual(items[1].usedPercent, 0)
        XCTAssertEqual(items[1].remainingPercent, 100)
        XCTAssertEqual(items[1].detail, "Resets May 26 at 10:28 PM")
    }

    func testGeminiParserKeepsRenderedResetTimesWhenUsageIsZero() throws {
        let renderedText = """
        BODY INNER TEXT
        Gemini Usage limits PRO Updated 1 hr ago Current usage 0% used Resets at 2:28 AM Weekly limit Resets May 26 at 9:28 PM 0% used Get 20x more usage than AI Pro
        DOM AND SHADOW TEXT
        """

        let items = GeminiUsageParser.parse(renderedText)

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].detail, "Resets at 2:28 AM")
        XCTAssertEqual(items[1].detail, "Resets May 26 at 9:28 PM")
    }

    func testGeminiParserRejectsHtmlAndScriptPercentages() throws {
        let html = """
        <!doctype html><html lang="en" dir="ltr"><head><script>window.foo = 1%</script></head>
        </script><!-- Google Tag Manager --> 92%
        Gemini usage 1%
        """

        XCTAssertTrue(GeminiUsageParser.parse(html).isEmpty)
    }

    func testLiveCodexRefreshUsesAppServerBeforeOAuth() throws {
        let calls = CallLog()
        let appServerLimits = makeRateLimits(sourcePath: "codex app-server", usedPercent: 12)
        let oauthLimits = makeRateLimits(sourcePath: "codex oauth wham/usage", usedPercent: 34)
        let plan = CodexRefreshPlan(
            loadAppServerRateLimits: {
                calls.append("app-server")
                return appServerLimits
            },
            loadOAuthRateLimits: { _ in
                calls.append("oauth")
                return oauthLimits
            },
            loadLocalSnapshot: { _ in
                calls.append("local")
                return UsageSnapshot()
            },
            loadCachedRateLimits: { nil }
        )

        let snapshot = try plan.loadSnapshot(codexHome: "/tmp/codex", dataSource: .liveOAuth)

        XCTAssertEqual(calls.values, ["app-server"])
        XCTAssertEqual(snapshot.rateLimits?.sourcePath, "codex app-server")
        XCTAssertNil(snapshot.errorMessage)
    }

    func testLiveCodexRefreshFallsBackToOAuthWhenAppServerFails() throws {
        let calls = CallLog()
        let oauthLimits = makeRateLimits(sourcePath: "codex oauth wham/usage", usedPercent: 34)
        let plan = CodexRefreshPlan(
            loadAppServerRateLimits: {
                calls.append("app-server")
                throw CodexRefreshTestError.failed("app-server unavailable")
            },
            loadOAuthRateLimits: { _ in
                calls.append("oauth")
                return oauthLimits
            },
            loadLocalSnapshot: { _ in
                calls.append("local")
                return UsageSnapshot()
            },
            loadCachedRateLimits: { nil }
        )

        let snapshot = try plan.loadSnapshot(codexHome: "/tmp/codex", dataSource: .liveOAuth)

        XCTAssertEqual(calls.values, ["app-server", "oauth"])
        XCTAssertEqual(snapshot.rateLimits?.sourcePath, "codex oauth wham/usage")
        XCTAssertNil(snapshot.errorMessage)
    }

    func testLiveCodexRefreshUsesCachedReadingWhenLiveRoutesFail() throws {
        let calls = CallLog()
        let cachedLimits = makeRateLimits(sourcePath: "codex oauth wham/usage", usedPercent: 56)
        let plan = CodexRefreshPlan(
            loadAppServerRateLimits: {
                calls.append("app-server")
                throw CodexRefreshTestError.failed("app-server unavailable")
            },
            loadOAuthRateLimits: { _ in
                calls.append("oauth")
                throw CodexRefreshTestError.failed("oauth unavailable")
            },
            loadLocalSnapshot: { _ in
                calls.append("local")
                return UsageSnapshot()
            },
            loadCachedRateLimits: {
                calls.append("cache")
                return cachedLimits
            }
        )

        let snapshot = try plan.loadSnapshot(codexHome: "/tmp/codex", dataSource: .liveOAuth)

        XCTAssertEqual(calls.values, ["app-server", "oauth", "cache"])
        XCTAssertEqual(snapshot.rateLimits?.primary.usedPercent, 56)
        XCTAssertEqual(snapshot.errorMessage, "Live Codex refresh failed. Showing the last good Codex reading.")
    }

    private func makeRateLimits(sourcePath: String, usedPercent: Double) -> CodexRateLimits {
        CodexRateLimits(
            primary: RateLimitWindow(
                usedPercent: usedPercent,
                windowMinutes: 300,
                resetsAt: Date(timeIntervalSince1970: 1_779_000_000)
            ),
            secondary: RateLimitWindow(
                usedPercent: usedPercent / 2,
                windowMinutes: 10_080,
                resetsAt: Date(timeIntervalSince1970: 1_779_604_800)
            ),
            credits: nil,
            planType: "prolite",
            capturedAt: Date(timeIntervalSince1970: 1_778_982_000),
            sourcePath: sourcePath
        )
    }

}

private enum CodexRefreshTestError: LocalizedError {
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

private final class CallLog: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValues: [String] = []

    var values: [String] {
        lock.lock()
        defer { lock.unlock() }
        return storedValues
    }

    func append(_ value: String) {
        lock.lock()
        storedValues.append(value)
        lock.unlock()
    }
}
