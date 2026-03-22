import SwiftUI

struct AnalysisResultCard: View {
    let analysis: CryAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(reasonColor.opacity(0.12))
                        .frame(width: 50, height: 50)

                    Image(systemName: analysis.reason.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(reasonColor)
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(analysis.reason.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 12) {
                        Label("\(Int(analysis.confidence * 100))%", systemImage: "chart.bar.fill")
                        Label(formattedDuration, systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }

                Spacer()
            }

            Text(analysis.tip)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }

    private var formattedDuration: String {
        if analysis.durationSeconds < 60 {
            return "\(analysis.durationSeconds)s"
        }
        return "\(analysis.durationSeconds / 60)m \(analysis.durationSeconds % 60)s"
    }

    private var reasonColor: Color {
        switch analysis.reason {
        case .hungry: return .orange
        case .tired: return .indigo
        case .uncomfortable: return .teal
        case .needsAttention: return .pink
        case .pain: return .red
        case .gassy: return .mint
        case .overstimulated: return .purple
        case .unknown: return .gray
        }
    }
}
