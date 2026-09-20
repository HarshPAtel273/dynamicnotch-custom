import Foundation
internal import Security

struct ClaudeUsageProvider: AIUsageProviding {
    let provider: AIProviderKind = .claude

    private let credentialsURL: URL
    private let session: URLSession

    init(
        homeDirectory: URL = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true),
        session: URLSession = .shared
    ) {
        self.credentialsURL = homeDirectory.appendingPathComponent(".claude/.credentials.json")
        self.session = session
    }

    func fetchSnapshot() async -> AIUsageSnapshot {
        guard var credentials = loadCredentials() else {
            return .unavailable(.claude)
        }

        if shouldRefresh(credentials),
           let refreshed = await refreshCredentials(credentials) {
            credentials = refreshed
        }

        do {
            let data = try await fetchUsage(accessToken: credentials.accessToken)
            return try Self.parseUsage(data, fetchedAt: .now)
        } catch {
            if let refreshed = await refreshCredentials(credentials),
               let data = try? await fetchUsage(accessToken: refreshed.accessToken),
               let snapshot = try? Self.parseUsage(data, fetchedAt: .now) {
                return snapshot
            }
            return .unavailable(.claude, summary: "Couldn't load usage")
        }
    }

    private struct OAuthCredentials {
        var accessToken: String
        var refreshToken: String?
        var expiresAt: Date?
    }

    private func loadCredentials() -> OAuthCredentials? {
        if let data = try? Data(contentsOf: credentialsURL),
           let credentials = parseCredentialsJSON(data) {
            return credentials
        }

        return loadCredentialsFromKeychain()
    }

    private func loadCredentialsFromKeychain() -> OAuthCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data else {
            return nil
        }
        return parseCredentialsJSON(data)
    }

    private func parseCredentialsJSON(_ data: Data) -> OAuthCredentials? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        let oauth = (json["claudeAiOauth"] as? [String: Any]) ?? json
        guard let accessToken = oauth["accessToken"] as? String, !accessToken.isEmpty else {
            return nil
        }

        let expiresAt: Date?
        if let millis = oauth["expiresAt"] as? Double {
            expiresAt = Date(timeIntervalSince1970: millis / 1000)
        } else if let millis = oauth["expiresAt"] as? Int {
            expiresAt = Date(timeIntervalSince1970: Double(millis) / 1000)
        } else {
            expiresAt = nil
        }

        return OAuthCredentials(
            accessToken: accessToken,
            refreshToken: oauth["refreshToken"] as? String,
            expiresAt: expiresAt
        )
    }

    private func shouldRefresh(_ credentials: OAuthCredentials) -> Bool {
        guard let expiresAt = credentials.expiresAt else { return false }
        return expiresAt.timeIntervalSinceNow < 5 * 60
    }

    private func refreshCredentials(_ credentials: OAuthCredentials) async -> OAuthCredentials? {
        guard let refreshToken = credentials.refreshToken, !refreshToken.isEmpty else {
            return nil
        }

        var request = URLRequest(url: URL(string: "https://platform.claude.com/v1/oauth/token")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": "9d1c250a-e61b-44d9-88ed-5944d1962f5e",
            "scope": "user:profile user:inference user:sessions:claude_code user:mcp_servers"
        ])

        guard
            let (data, response) = try? await AIUsageHTTPClient.data(for: request, session: session),
            (200..<300).contains(response.statusCode),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let accessToken = json["access_token"] as? String,
            !accessToken.isEmpty
        else {
            return nil
        }

        let expiresIn = (json["expires_in"] as? Double) ?? (json["expires_in"] as? Int).map(Double.init) ?? 3600
        return OAuthCredentials(
            accessToken: accessToken,
            refreshToken: (json["refresh_token"] as? String) ?? refreshToken,
            expiresAt: Date().addingTimeInterval(expiresIn)
        )
    }

    private func fetchUsage(accessToken: String) async throws -> Data {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        let (data, response) = try await AIUsageHTTPClient.data(for: request, session: session)
        guard (200..<300).contains(response.statusCode) else {
            throw URLError(.userAuthenticationRequired)
        }
        return data
    }

    static func parseUsage(_ data: Data, fetchedAt: Date = .now) throws -> AIUsageSnapshot {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        var windows: [AIUsageWindow] = []

        if let fiveHour = json["five_hour"] as? [String: Any],
           let window = window(from: fiveHour, id: "five_hour", title: "5h") {
            windows.append(window)
        }

        if let sevenDay = json["seven_day"] as? [String: Any],
           let window = window(from: sevenDay, id: "seven_day", title: "7d") {
            windows.append(window)
        }

        guard !windows.isEmpty else {
            throw URLError(.cannotParseResponse)
        }

        let worstFraction = windows.compactMap(\.usedFraction).max() ?? 0
        let summary = windows.map(\.detail).joined(separator: " · ")

        return AIUsageSnapshot(
            provider: .claude,
            status: AIUsageSnapshot.status(forUsedFraction: worstFraction),
            summary: summary,
            windows: windows,
            fetchedAt: fetchedAt
        )
    }

    private static func window(from json: [String: Any], id: String, title: String) -> AIUsageWindow? {
        let utilization = doubleValue(json["utilization"]) ?? 0
        let fraction = utilization > 1 ? utilization / 100 : utilization
        let percent = fraction * 100
        return AIUsageWindow(
            id: id,
            title: title,
            usedFraction: fraction,
            detail: AIUsageSnapshot.percentDetail(usedPercent: percent, windowTitle: title),
            resetsAt: dateValue(json["resets_at"])
        )
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

    private static func dateValue(_ value: Any?) -> Date? {
        guard let string = value as? String else { return nil }
        return ISO8601DateFormatter().date(from: string)
    }
}
