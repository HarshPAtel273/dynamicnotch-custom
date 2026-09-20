import Foundation

protocol AIUsageProviding: Sendable {
    var provider: AIProviderKind { get }
    func fetchSnapshot() async -> AIUsageSnapshot
}

enum AIUsageHTTPClient {
    static func data(
        for request: URLRequest,
        session: URLSession = .shared
    ) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, http)
    }
}

enum AIUsageSQLiteReader {
    static func stringValue(databasePath: String, key: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        process.arguments = [
            databasePath,
            "SELECT value FROM ItemTable WHERE key = '\(key.replacingOccurrences(of: "'", with: "''"))';"
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let value = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}
