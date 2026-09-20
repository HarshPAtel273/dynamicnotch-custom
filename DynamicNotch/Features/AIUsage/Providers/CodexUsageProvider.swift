import Foundation

struct CodexUsageProvider: AIUsageProviding {
    let provider: AIProviderKind = .chatgpt

    private let authURL: URL
    private let session: URLSession

    init(
        homeDirectory: URL = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true),
        session: URLSession = .shared
    ) {
        if let codexHome = ProcessInfo.processInfo.environment["CODEX_HOME"], !codexHome.isEmpty {
            self.authURL = URL(fileURLWithPath: codexHome, isDirectory: true)
                .appendingPathComponent("auth.json")
        } else {
            self.authURL = homeDirectory.appendingPathComponent(".codex/auth.json")
        }
        self.session = session
    }

    func fetchSnapshot() async -> AIUsageSnapshot {
        guard let auth = loadAuth() else {
            return .unavailable(.chatgpt)
        }

        do {
            let data = try await fetchUsage(auth: auth)
            return try Self.parseUsage(data, fetchedAt: .now)
        } catch {
            if let refreshed = await refreshAuth(auth),
               let data = try? await fetchUsage(auth: refreshed),
               let snapshot = try? Self.parseUsage(data, fetchedAt: .now) {
                return snapshot
            }
            return .unavailable(.chatgpt, summary: "Couldn't load usage")
        }
    }

    private struct AuthTokens {
        var accessToken: String
        var refreshToken: String?
        var accountID: String?
    }

    private func loadAuth() -> AuthTokens? {
        guard
            let data = try? Data(contentsOf: authURL),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let tokens = json["tokens"] as? [String: Any],
            let accessToken = tokens["access_token"] as? String,
            !accessToken.isEmpty
        else {
            return nil
        }

        return AuthTokens(
            accessToken: accessToken,
            refreshToken: tokens["refresh_token"] as? String,
            accountID: tokens["account_id"] as? String
        )
    }

    private func refreshAuth(_ auth: AuthTokens) async -> AuthTokens? {
        guard let refreshToken = auth.refreshToken, !refreshToken.isEmpty else {
            return nil
        }

        var request = URLRequest(url: URL(string: "https://auth.openai.com/oauth/token")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": "app_EMoamEEZ73f0CkXaXp7hrann"
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

        return AuthTokens(
            accessToken: accessToken,
            refreshToken: (json["refresh_token"] as? String) ?? refreshToken,
            accountID: auth.accountID
        )
    }

    private func fetchUsage(auth: AuthTokens) async throws -> Data {
        var request = URLRequest(url: URL(string: "https://chatgpt.com/backend-api/wham/usage")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(auth.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("https://chatgpt.com", forHTTPHeaderField: "Origin")
        request.setValue("https://chatgpt.com/", forHTTPHeaderField: "Referer")
        if let accountID = auth.accountID {
            request.setValue(accountID, forHTTPHeaderField: "ChatGPT-Account-Id")
        }

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

        let rateLimit = (json["rate_limit"] as? [String: Any]) ?? json
        var windows: [AIUsageWindow] = []

        if let primary = rateLimit["primary_window"] as? [String: Any],
           let window = window(from: primary, id: "primary", fallbackTitle: "5h") {
            windows.append(window)
        }

        if let secondary = rateLimit["secondary_window"] as? [String: Any],
           let window = window(from: secondary, id: "secondary", fallbackTitle: "7d") {
            windows.append(window)
        }

        guard !windows.isEmpty else {
            throw URLError(.cannotParseResponse)
        }

        let worstFraction = windows.compactMap(\.usedFraction).max() ?? 0
        let summary = windows.map(\.detail).joined(separator: " · ")

        return AIUsageSnapshot(
            provider: .chatgpt,
            status: AIUsageSnapshot.status(forUsedFraction: worstFraction),
            summary: summary,
            windows: windows,
            fetchedAt: fetchedAt
        )
    }

    private static func window(
        from json: [String: Any],
        id: String,
        fallbackTitle: String
    ) -> AIUsageWindow? {
        let usedPercentRaw = doubleValue(json["used_percent"]) ?? 0
        // API usually returns 0...100; tolerate 0...1 fractions.
        let displayPercent = usedPercentRaw <= 1 ? usedPercentRaw * 100 : usedPercentRaw
        let usedFraction = displayPercent / 100

        let seconds = intValue(json["limit_window_seconds"])
        let title: String
        switch seconds {
        case 18000: title = "5h"
        case 604800: title = "7d"
        default: title = fallbackTitle
        }

        let resetsAt: Date?
        if let reset = intValue(json["reset_at"]) {
            resetsAt = Date(timeIntervalSince1970: TimeInterval(reset))
        } else if let reset = doubleValue(json["reset_at"]) {
            resetsAt = Date(timeIntervalSince1970: reset)
        } else {
            resetsAt = nil
        }

        return AIUsageWindow(
            id: id,
            title: title,
            usedFraction: usedFraction,
            detail: AIUsageSnapshot.percentDetail(usedPercent: displayPercent, windowTitle: title),
            resetsAt: resetsAt
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

    private static func intValue(_ value: Any?) -> Int? {
        switch value {
        case let number as Int: return number
        case let number as Double: return Int(number)
        case let number as NSNumber: return number.intValue
        case let string as String: return Int(string)
        default: return nil
        }
    }
}
