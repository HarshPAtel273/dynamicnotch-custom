import Foundation

enum AIProviderKind: String, CaseIterable, Identifiable, Hashable {
    case cursor
    case claude
    case chatgpt

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cursor: return "Cursor"
        case .claude: return "Claude"
        case .chatgpt: return "ChatGPT"
        }
    }

    var systemImage: String {
        switch self {
        case .cursor: return "chevron.left.forwardslash.chevron.right"
        case .claude: return "bubble.left.and.bubble.right.fill"
        case .chatgpt: return "sparkles"
        }
    }

    var billingURL: URL {
        switch self {
        case .cursor:
            return URL(string: "https://cursor.com/dashboard/spending")!
        case .claude:
            return URL(string: "https://claude.ai/settings/usage")!
        case .chatgpt:
            return URL(string: "https://chatgpt.com/#settings")!
        }
    }
}

enum AIUsageStatus: String, Equatable {
    case ok
    case nearLimit
    case exhausted
    case unavailable
}

struct AIUsageWindow: Equatable, Identifiable {
    let id: String
    let title: String
    /// 0...1 fraction used when known.
    let usedFraction: Double?
    let detail: String
    let resetsAt: Date?

    init(
        id: String,
        title: String,
        usedFraction: Double?,
        detail: String,
        resetsAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.usedFraction = usedFraction.map { min(max($0, 0), 1) }
        self.detail = detail
        self.resetsAt = resetsAt
    }
}

struct AIUsageSnapshot: Equatable, Identifiable {
    var id: AIProviderKind { provider }

    let provider: AIProviderKind
    let status: AIUsageStatus
    let summary: String
    let windows: [AIUsageWindow]
    let fetchedAt: Date

    static func unavailable(_ provider: AIProviderKind, summary: String = "Not signed in") -> AIUsageSnapshot {
        AIUsageSnapshot(
            provider: provider,
            status: .unavailable,
            summary: summary,
            windows: [],
            fetchedAt: .now
        )
    }

    static func status(forUsedFraction fraction: Double?) -> AIUsageStatus {
        guard let fraction else { return .ok }
        if fraction >= 1 { return .exhausted }
        if fraction >= 0.8 { return .nearLimit }
        return .ok
    }

    static func currencyDetail(remainingCents: Int, limitCents: Int) -> String {
        let remaining = Double(remainingCents) / 100
        let limit = Double(limitCents) / 100
        return String(format: "$%.2f of $%.2f left", remaining, limit)
    }

    static func percentDetail(usedPercent: Double, windowTitle: String) -> String {
        let remaining = max(0, 100 - usedPercent)
        return String(format: "%.0f%% of %@ left", remaining, windowTitle)
    }
}
