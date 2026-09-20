import SwiftUI
internal import AppKit

struct AIUsageHomePageNotchView: View {
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @StateObject private var viewModel = AIUsageViewModel()

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 8) {
                HStack {
                    Text(verbatim: "AI Usage")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))

                    Spacer()

                    if viewModel.isRefreshing {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }
                .padding(.horizontal, 4)

                VStack(spacing: 6) {
                    ForEach(viewModel.snapshots) { snapshot in
                        providerRow(snapshot)
                    }
                }
            }
        }
        .padding(.horizontal, isDynamicIsland ? 2 : 4)
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }

    @ViewBuilder
    private func providerRow(_ snapshot: AIUsageSnapshot) -> some View {
        Button {
            NSWorkspace.shared.open(snapshot.provider.billingURL)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Image(systemName: snapshot.provider.systemImage)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(statusColor(snapshot.status))
                        .frame(width: 16)

                    Text(snapshot.provider.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))

                    Spacer(minLength: 8)

                    Text(snapshot.summary)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                }

                if let fraction = primaryFraction(for: snapshot) {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.1))
                            Capsule()
                                .fill(statusColor(snapshot.status).opacity(0.85))
                                .frame(width: max(4, proxy.size.width * fraction))
                        }
                    }
                    .frame(height: 4)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }

    private func primaryFraction(for snapshot: AIUsageSnapshot) -> Double? {
        if let maxFraction = snapshot.windows.compactMap(\.usedFraction).max() {
            return maxFraction
        }
        return nil
    }

    private func statusColor(_ status: AIUsageStatus) -> Color {
        switch status {
        case .ok:
            return Color(red: 0.45, green: 0.78, blue: 0.62)
        case .nearLimit:
            return .orange
        case .exhausted:
            return Color(red: 0.98, green: 0.35, blue: 0.35)
        case .unavailable:
            return .white.opacity(0.45)
        }
    }
}
