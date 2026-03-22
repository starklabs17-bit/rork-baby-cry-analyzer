import Foundation
import OSLog

nonisolated struct ChatMessage: Codable, Sendable {
    let role: String
    let content: String
}

nonisolated struct ChatRequestBody: Codable, Sendable {
    let messages: [ChatMessage]
}

nonisolated struct CryAnalysisResponse: Codable, Sendable {
    let reason: String
    let confidence: Double
    let tip: String
}

@MainActor
class CryAnalysisService {
    private let toolkitURL: String
    private let logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BabyCryAnalyzer", category: "CryAnalysis")
    private let maxRetries = 2

    init() {
        self.toolkitURL = Config.EXPO_PUBLIC_TOOLKIT_URL
    }

    func analyzeCry(durationSeconds: Int, averageDecibels: Float, peakDecibels: Float) async throws -> CryAnalysis {
        let prompt = buildPrompt(durationSeconds: durationSeconds, averageDecibels: averageDecibels, peakDecibels: peakDecibels)

        var lastError: Error?
        for attempt in 0...maxRetries {
            if attempt > 0 {
                try await Task.sleep(for: .seconds(Double(attempt)))
            }
            do {
                let responseText = try await callAgentChat(prompt: prompt)
                let analysisResponse = parseAnalysis(from: responseText)

                let reason = CryReason(rawValue: analysisResponse.reason) ?? .unknown
                return CryAnalysis(
                    reason: reason,
                    confidence: analysisResponse.confidence,
                    tip: analysisResponse.tip,
                    durationSeconds: durationSeconds,
                    averageDecibels: averageDecibels
                )
            } catch {
                lastError = error
                logger.error("Attempt \(attempt + 1) failed: \(error.localizedDescription)")
            }
        }
        throw lastError ?? CryAnalysisError.serverError(500)
    }

    private func callAgentChat(prompt: String) async throws -> String {
        let baseURL = toolkitURL.isEmpty ? "https://toolkit.rork.com" : toolkitURL

        guard let url = URL(string: "\(baseURL)/agent/chat") else {
            throw CryAnalysisError.invalidURL
        }

        let requestBody = ChatRequestBody(messages: [
            ChatMessage(role: "user", content: prompt)
        ])

        let jsonData = try JSONEncoder().encode(requestBody)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let projectId = Config.EXPO_PUBLIC_PROJECT_ID
        if !projectId.isEmpty {
            request.setValue(projectId, forHTTPHeaderField: "x-project-id")
        }
        let teamId = Config.EXPO_PUBLIC_TEAM_ID
        if !teamId.isEmpty {
            request.setValue(teamId, forHTTPHeaderField: "x-team-id")
        }
        request.timeoutInterval = 45
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CryAnalysisError.serverError(0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            logger.error("HTTP \(httpResponse.statusCode): \(body, privacy: .private)")
            throw CryAnalysisError.serverError(httpResponse.statusCode)
        }

        return try extractText(from: data)
    }

    private func extractText(from data: Data) throws -> String {
        guard let raw = String(data: data, encoding: .utf8) else {
            throw CryAnalysisError.decodingError
        }

        var fullText = ""
        for line in raw.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("0:") {
                var content = String(trimmed.dropFirst(2))
                content = content.trimmingCharacters(in: .init(charactersIn: "\""))
                content = content.replacingOccurrences(of: "\\n", with: "\n")
                fullText += content
            } else if trimmed.hasPrefix("data:") {
                let jsonStr = String(trimmed.dropFirst(5))
                if let jsonData = jsonStr.data(using: .utf8),
                   let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    if let choices = obj["choices"] as? [[String: Any]],
                       let msg = choices.first?["delta"] as? [String: Any],
                       let content = msg["content"] as? String {
                        fullText += content
                    } else if let content = obj["content"] as? String {
                        fullText += content
                    }
                }
            }
        }
        if !fullText.isEmpty { return fullText }

        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let text = obj["text"] as? String { return text }
            if let choices = obj["choices"] as? [[String: Any]],
               let msg = choices.first?["message"] as? [String: Any],
               let content = msg["content"] as? String { return content }
            if let content = obj["content"] as? String { return content }
            if let result = obj["result"] as? String { return result }
        }

        return raw
    }

    private func parseAnalysis(from text: String) -> CryAnalysisResponse {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let jsonData = cleaned.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(CryAnalysisResponse.self, from: jsonData) {
            return parsed
        }

        if let start = cleaned.firstIndex(of: "{"),
           let end = cleaned.lastIndex(of: "}") {
            let jsonSubstr = String(cleaned[start...end])
            if let jsonData = jsonSubstr.data(using: .utf8),
               let parsed = try? JSONDecoder().decode(CryAnalysisResponse.self, from: jsonData) {
                return parsed
            }
        }

        return inferFromText(text)
    }

    private func inferFromText(_ text: String) -> CryAnalysisResponse {
        let lower = text.lowercased()
        var reason = "Unknown"
        for r in CryReason.allCases where r != .unknown {
            if lower.contains(r.rawValue.lowercased()) {
                reason = r.rawValue
                break
            }
        }
        return CryAnalysisResponse(reason: reason, confidence: 0.6, tip: cleanTipFromText(text))
    }

    private func cleanTipFromText(_ text: String) -> String {
        let sentences = text.components(separatedBy: ".")
        let tips = sentences.filter { $0.lowercased().contains("try") || $0.lowercased().contains("consider") || $0.lowercased().contains("may") || $0.lowercased().contains("suggest") }
        if let tip = tips.first {
            return tip.trimmingCharacters(in: .whitespacesAndNewlines) + "."
        }
        return sentences.count > 1 ? sentences[1].trimmingCharacters(in: .whitespacesAndNewlines) + "." : "Try comforting your baby with gentle rocking."
    }

    private func buildPrompt(durationSeconds: Int, averageDecibels: Float, peakDecibels: Float) -> String {
        let intensity: String
        if averageDecibels > -15 {
            intensity = "very loud and intense"
        } else if averageDecibels > -25 {
            intensity = "moderately loud"
        } else if averageDecibels > -35 {
            intensity = "soft and gentle"
        } else {
            intensity = "very quiet, almost whimpering"
        }

        let durationDesc: String
        if durationSeconds < 10 {
            durationDesc = "very brief (under 10 seconds)"
        } else if durationSeconds < 30 {
            durationDesc = "short (about \(durationSeconds) seconds)"
        } else if durationSeconds < 60 {
            durationDesc = "moderate duration (\(durationSeconds) seconds)"
        } else {
            durationDesc = "prolonged (over \(durationSeconds / 60) minute\(durationSeconds >= 120 ? "s" : ""))"
        }

        return """
        You are a pediatric care assistant AI. Based on the following audio characteristics of a baby crying, determine the most likely reason for the crying.

        Audio characteristics:
        - Duration: \(durationDesc)
        - Intensity: \(intensity)
        - Average volume: \(String(format: "%.1f", averageDecibels)) dB
        - Peak volume: \(String(format: "%.1f", peakDecibels)) dB

        Based on common patterns in baby crying:
        - Hungry cries tend to be rhythmic, repetitive, and moderate intensity that builds over time
        - Tired cries are often whiny, intermittent, with lower intensity
        - Pain cries are sudden, sharp, high-pitched, and very intense
        - Uncomfortable cries (wet diaper, too hot/cold) are fussy, intermittent, moderate
        - Gassy cries often come in short bursts with pauses
        - Needs attention cries are moderate, stop-and-start, looking for response
        - Overstimulated cries build gradually, often with fussing before full crying

        Respond ONLY with a JSON object (no markdown, no extra text) in this exact format:
        {"reason": "<one of: Hungry, Tired, Uncomfortable, Needs Attention, Pain, Gassy, Overstimulated, Unknown>", "confidence": <0.0 to 1.0>, "tip": "<brief, warm, helpful tip for the parent in 1-2 sentences>"}
        """
    }
}

nonisolated enum CryAnalysisError: Error, LocalizedError, Sendable {
    case invalidURL
    case serverError(Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Unable to connect to analysis service."
        case .serverError(let code): return "Analysis service returned an error (\(code)). Please try again."
        case .decodingError: return "Unable to process the analysis result."
        }
    }
}
