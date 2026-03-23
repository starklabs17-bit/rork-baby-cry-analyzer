import Foundation
import OSLog
import UniformTypeIdentifiers

nonisolated struct SpeechTranscriptionResponse: Codable, Sendable {
    let text: String
    let language: String
}

nonisolated enum SpeechTranscriptionError: Error, LocalizedError, Sendable {
    case invalidURL
    case invalidAudio
    case serverError(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to connect to the voice recognition service."
        case .invalidAudio:
            return "This audio file could not be prepared for voice recognition."
        case .serverError:
            return "Voice recognition is temporarily unavailable."
        case .decodingFailed:
            return "The voice recognition response could not be read."
        }
    }
}

@MainActor
final class SpeechTranscriptionService {
    private let logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BabyCryAnalyzer", category: "SpeechTranscription")
    private let toolkitURL: String = Config.EXPO_PUBLIC_TOOLKIT_URL

    func transcribeAudio(at url: URL) async throws -> SpeechTranscriptionResponse {
        let baseURL: String = toolkitURL.isEmpty ? "https://toolkit.rork.com" : toolkitURL
        guard let endpoint: URL = URL(string: "\(baseURL)/stt/transcribe/") else {
            throw SpeechTranscriptionError.invalidURL
        }

        let audioData: Data = try Data(contentsOf: url)
        guard !audioData.isEmpty else {
            throw SpeechTranscriptionError.invalidAudio
        }

        let boundary: String = "Boundary-\(UUID().uuidString)"
        var request: URLRequest = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let projectId: String = Config.EXPO_PUBLIC_PROJECT_ID
        if !projectId.isEmpty {
            request.setValue(projectId, forHTTPHeaderField: "x-project-id")
        }

        let teamId: String = Config.EXPO_PUBLIC_TEAM_ID
        if !teamId.isEmpty {
            request.setValue(teamId, forHTTPHeaderField: "x-team-id")
        }

        request.httpBody = createMultipartBody(audioData: audioData, fileURL: url, boundary: boundary)

        let (data, response): (Data, URLResponse) = try await URLSession.shared.data(for: request)
        guard let httpResponse: HTTPURLResponse = response as? HTTPURLResponse else {
            throw SpeechTranscriptionError.serverError(0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body: String = String(data: data, encoding: .utf8) ?? "no body"
            logger.error("Voice recognition HTTP \(httpResponse.statusCode): \(body, privacy: .private)")
            throw SpeechTranscriptionError.serverError(httpResponse.statusCode)
        }

        guard let decoded: SpeechTranscriptionResponse = try? JSONDecoder().decode(SpeechTranscriptionResponse.self, from: data) else {
            throw SpeechTranscriptionError.decodingFailed
        }

        return decoded
    }

    private func createMultipartBody(audioData: Data, fileURL: URL, boundary: String) -> Data {
        var body: Data = Data()
        let fileName: String = fileURL.lastPathComponent.isEmpty ? "recording.m4a" : fileURL.lastPathComponent
        let mimeType: String = mimeType(for: fileURL)

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        return body
    }

    private func mimeType(for url: URL) -> String {
        guard let type: UTType = UTType(filenameExtension: url.pathExtension.lowercased()) else {
            return "audio/m4a"
        }

        if type.conforms(to: .wav) {
            return "audio/wav"
        }
        if type.conforms(to: .mpeg4Audio) {
            return "audio/m4a"
        }
        if type.conforms(to: .mp3) {
            return "audio/mpeg"
        }
        if type.conforms(to: .audio) {
            return type.preferredMIMEType ?? "audio/m4a"
        }

        return "audio/m4a"
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
