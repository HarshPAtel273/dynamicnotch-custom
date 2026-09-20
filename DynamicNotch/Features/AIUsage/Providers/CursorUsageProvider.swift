import Foundation

struct CursorUsageProvider: AIUsageProviding {
    let provider: AIProviderKind = .cursor

    private let databasePath: String
    private let session: URLSession

    init(
        databasePath: String = NSHomeDirectory() + "/Library/Application Support/Cursor/User/globalStorage/state.vscdb",
        session: URLSession = .shared
    ) {
        self.databasePath = databasePath
        self.session = session
    }

    func fetchSnapshot() async -> AIUsageSnapshot {
        guard var accessToken = AIUsageSQLiteReader.stringValue(
            databasePath: databasePath,
            key: "cursorAuth/accessToken"
        ) else {
            return .unavailable(.cursor)
        }

        if let refreshed = await refreshAccessTokenIfNeeded(currentAccessToken: accessToken) {
            accessToken = refreshed
        }

        do {
            let data = try await fetchCurrentPeriodUsage(accessToken: accessToken)
            return try Self.parsePeriodUsage(data, fetchedAt: .now)
        } catch {
            return .unavailable(.cursor, summary: "Couldn't load usage")
        }
    }

    private func refreshAccessTokenIfNeeded(currentAccessToken: String) async -> String? {
        guard shouldRefresh(accessToken: currentAccessToken) else { return nil }
        guard let refreshToken = AIUsageSQLiteReader.stringValue(
            databasePath: databasePath,
            key: "cursorAuth/refreshToken"
        ) else {
            return nil
        }

        var request = URLRequest(url: URL(string: "https://api2.cursor.sh/oauth/token")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "grant_type": "refresh_token",
            "client_id": "KbZUR41cY7W6zRSdpSUJ7I7mLYBKOCmB",
            "refresh_token": refreshToken
        ])

        guard
            let (data, response) = try? await AIUsageHTTPClient.data(for: request, session: session),
            (200..<300).contains(response.statusCode),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            json["shouldLogout"] as? Bool != true,
            let accessToken = json["access_token"] as? String,
            !accessToken.isEmpty
        else {
            return nil
        }

        return accessToken
    }

    private func shouldRefresh(accessToken: String) -> Bool {
        guard let payload = Self.decodeJWTPayload(accessToken),
              let exp = payload["exp"] as? TimeInterval else {
            return false
        }
        return Date(timeIntervalSince1970: exp).timeIntervalSinceNow < 5 * 60
    }

    private func fetchCurrentPeriodUsage(accessToken: String) async throws -> Data {
        var request = URLRequest(
            url: URL(string: "https://api2.cursor.sh/aiserver.v1.DashboardService/GetCurrentPeriodUsage")!
        )
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "Connect-Protocol-Version")
        request.httpBody = Data("{}".utf8)

        let (data, response) = try await AIUsageHTTPClient.data(for: request, session: session)
        guard (200..<300).contains(response.statusCode) else {
            throw URLError(.userAuthenticationRequired)
        }
        return data
    }

    static func parsePeriodUsage(_ data: Data, fetchedAt: Date = .now) throws -> AIUsageSnapshot {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let planUsage = json["planUsage"] as? [String: Any]
        else {
            throw URLError(.cannotParseResponse)
        }

        let remainingCents = intValue(planUsage["remaining"]) ?? 0
        let limitCents = intValue(planUsage["limit"]) ?? 0
        let totalPercent = doubleValue(planUsage["totalPercentUsed"]) ?? {
            guard limitCents > 0 else { return 0 }
            return (1 - Double(remainingCents) / Double(limitCents)) * 100
        }()

        let usedFraction = limitCents > 0
            ? 1 - Double(remainingCents) / Double(limitCents)
            : totalPercent / 100

        let resetsAt = dateFromUnixMilliseconds(json["billingCycleEnd"])
        let detail = AIUsageSnapshot.currencyDetail(remainingCents: remainingCents, limitCents: limitCents)
        let window = AIUsageWindow(
            id: "plan",
            title: "Plan",
            usedFraction: usedFraction,
            detail: detail,
            resetsAt: resetsAt
        )

        return AIUsageSnapshot(
            provider: .cursor,
            status: AIUsageSnapshot.status(forUsedFraction: usedFraction),
            summary: detail,
            windows: [window],
            fetchedAt: fetchedAt
        )
    }

    private static func decodeJWTPayload(_ token: String) -> [String: Any]? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    private static func intValue(_ value: Any?) -> Int? {
        switch value {
        case let number as Int: return number
        case let number as Double: return Int(number)
        case let number as NSNumber: return number.intValue
        case let string as String: return Int(string)
        default: return nil
        }
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        switch value {
        case let number as Double: return number
        case let number as Int: return Double(number)
        case let number as NSNumber: return number.doubleValue
        case let string as String: return Double(string)
        default: return nil
        }
    }

    private static func dateFromUnixMilliseconds(_ value: Any?) -> Date? {
        let millis: Double?
        switch value {
        case let string as String: millis = Double(string)
        case let number as Double: millis = number
        case let number as Int: millis = Double(number)
        case let number as NSNumber: millis = number.doubleValue
        default: millis = nil
        }
        guard let millis else { return nil }
        return Date(timeIntervalSince1970: millis / 1000)
    }
}
