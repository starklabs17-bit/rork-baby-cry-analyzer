import Foundation

nonisolated struct CryAnalysis: Identifiable, Codable, Sendable {
    let id: UUID
    let date: Date
    let reason: CryReason
    let confidence: Double
    let tip: String
    let durationSeconds: Int
    let averageDecibels: Float
    let transcript: String?
    let transcriptLanguage: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        reason: CryReason,
        confidence: Double,
        tip: String,
        durationSeconds: Int,
        averageDecibels: Float,
        transcript: String? = nil,
        transcriptLanguage: String? = nil
    ) {
        self.id = id
        self.date = date
        self.reason = reason
        self.confidence = confidence
        self.tip = tip
        self.durationSeconds = durationSeconds
        self.averageDecibels = averageDecibels
        self.transcript = transcript
        self.transcriptLanguage = transcriptLanguage
    }
}

nonisolated enum CryReason: String, Codable, CaseIterable, Sendable {
    case hungry = "Hungry"
    case tired = "Tired"
    case uncomfortable = "Uncomfortable"
    case needsAttention = "Needs Attention"
    case pain = "Pain"
    case gassy = "Gassy"
    case overstimulated = "Overstimulated"
    case unknown = "Unknown"

    var icon: String {
        switch self {
        case .hungry: return "fork.knife"
        case .tired: return "moon.zzz.fill"
        case .uncomfortable: return "thermometer.medium"
        case .needsAttention: return "heart.fill"
        case .pain: return "bandage.fill"
        case .gassy: return "wind"
        case .overstimulated: return "sparkles"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .hungry: return "hungry"
        case .tired: return "tired"
        case .uncomfortable: return "uncomfortable"
        case .needsAttention: return "attention"
        case .pain: return "pain"
        case .gassy: return "gassy"
        case .overstimulated: return "overstimulated"
        case .unknown: return "unknown"
        }
    }
}
