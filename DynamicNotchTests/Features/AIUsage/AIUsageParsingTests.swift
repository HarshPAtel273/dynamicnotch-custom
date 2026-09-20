import XCTest
@testable import DynamicNotch

final class AIUsageParsingTests: XCTestCase {
    func testCursorPeriodUsageParsing() throws {
        let json = """
        {
          "billingCycleEnd": "1771077734000",
          "planUsage": {
            "remaining": 16778,
            "limit": 40000,
            "totalPercentUsed": 58.055
          }
        }
        """.data(using: .utf8)!

        let snapshot = try CursorUsageProvider.parsePeriodUsage(json, fetchedAt: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(snapshot.provider, .cursor)
        XCTAssertEqual(snapshot.status, .ok)
        XCTAssertTrue(snapshot.summary.contains("167.78") || snapshot.summary.contains("$167.78"))
        XCTAssertEqual(snapshot.windows.count, 1)
        XCTAssertEqual(snapshot.windows[0].usedFraction!, 1 - (16778.0 / 40000.0), accuracy: 0.001)
    }

    func testClaudeUsageParsingUsesWorstWindow() throws {
        let json = """
        {
          "five_hour": { "utilization": 25, "resets_at": "2026-01-28T15:00:00Z" },
          "seven_day": { "utilization": 85, "resets_at": "2026-02-01T00:00:00Z" }
        }
        """.data(using: .utf8)!

        let snapshot = try ClaudeUsageProvider.parseUsage(json, fetchedAt: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(snapshot.provider, .claude)
        XCTAssertEqual(snapshot.status, .nearLimit)
        XCTAssertEqual(snapshot.windows.count, 2)
        XCTAssertEqual(snapshot.windows[0].usedFraction!, 0.25, accuracy: 0.001)
        XCTAssertEqual(snapshot.windows[1].usedFraction!, 0.85, accuracy: 0.001)
    }

    func testCodexUsageParsingReadsPrimaryAndSecondaryWindows() throws {
        let json = """
        {
          "rate_limit": {
            "primary_window": {
              "used_percent": 40,
              "limit_window_seconds": 18000,
              "reset_at": 1770000000
            },
            "secondary_window": {
              "used_percent": 10,
              "limit_window_seconds": 604800,
              "reset_at": 1770500000
            }
          }
        }
        """.data(using: .utf8)!

        let snapshot = try CodexUsageProvider.parseUsage(json, fetchedAt: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(snapshot.provider, .chatgpt)
        XCTAssertEqual(snapshot.status, .ok)
        XCTAssertEqual(snapshot.windows.map(\.title), ["5h", "7d"])
        XCTAssertEqual(snapshot.windows[0].usedFraction!, 0.4, accuracy: 0.001)
    }

    func testUsageStatusThresholds() {
        XCTAssertEqual(AIUsageSnapshot.status(forUsedFraction: 0.79), .ok)
        XCTAssertEqual(AIUsageSnapshot.status(forUsedFraction: 0.8), .nearLimit)
        XCTAssertEqual(AIUsageSnapshot.status(forUsedFraction: 1.0), .exhausted)
    }
}
