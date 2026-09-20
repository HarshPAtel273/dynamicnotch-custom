import Combine
import Foundation

@MainActor
final class AIUsageViewModel: ObservableObject {
    @Published private(set) var snapshots: [AIUsageSnapshot] = AIProviderKind.allCases.map {
        .unavailable($0, summary: "Loading…")
    }
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastError: String?

    private let providers: [any AIUsageProviding]
    private var refreshTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?

    init(providers: [any AIUsageProviding]? = nil) {
        self.providers = providers ?? [
            CursorUsageProvider(),
            ClaudeUsageProvider(),
            CodexUsageProvider()
        ]
    }

    func startMonitoring() {
        refresh()
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.refresh()
                }
            }
        }
    }

    func stopMonitoring() {
        pollTask?.cancel()
        pollTask = nil
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refresh() {
        refreshTask?.cancel()
        isRefreshing = true
        lastError = nil

        let providers = self.providers
        refreshTask = Task { [weak self] in
            let results = await withTaskGroup(of: AIUsageSnapshot.self, returning: [AIUsageSnapshot].self) { group in
                for provider in providers {
                    group.addTask {
                        await provider.fetchSnapshot()
                    }
                }

                var collected: [AIUsageSnapshot] = []
                for await snapshot in group {
                    collected.append(snapshot)
                }
                return collected
            }

            guard !Task.isCancelled else { return }

            let ordered = AIProviderKind.allCases.compactMap { kind in
                results.first(where: { $0.provider == kind })
            }

            await MainActor.run {
                guard let self else { return }
                // Keep prior good data when a refresh fails transiently.
                self.snapshots = ordered.map { snapshot in
                    if snapshot.status == .unavailable,
                       snapshot.summary == "Couldn't load usage",
                       let previous = self.snapshots.first(where: { $0.provider == snapshot.provider }),
                       previous.status != .unavailable {
                        return previous
                    }
                    return snapshot
                }
                self.isRefreshing = false
            }
        }
    }
}
