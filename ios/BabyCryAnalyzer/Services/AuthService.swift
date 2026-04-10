import Foundation
import Auth
import AuthenticationServices
import CryptoKit
import GoogleSignIn

@MainActor
@Observable
class AuthService {
    var currentUser: Auth.User?
    var isAuthenticated: Bool = false
    var isLoading: Bool = true

    private let client: AuthClient

    init() {
        let supabaseURL = AppConfig.supabaseURL
        let supabaseKey = AppConfig.supabaseAnonKey

        self.client = AuthClient(
            configuration: AuthClient.Configuration(
                url: URL(string: "\(supabaseURL)/auth/v1")!,
                headers: ["apikey": supabaseKey],
                flowType: .implicit,
                localStorage: KeychainLocalStorage()
            )
        )

        Task { await listenForAuthChanges() }
        Task { await loadSession() }
    }

    private func loadSession() async {
        defer { isLoading = false }
        do {
            let session = try await client.session
            currentUser = session.user
            isAuthenticated = true
        } catch {
            currentUser = nil
            isAuthenticated = false
        }
    }

    private func listenForAuthChanges() async {
        for await (event, session) in client.authStateChanges {
            switch event {
            case .signedIn, .tokenRefreshed, .userUpdated:
                currentUser = session?.user
                isAuthenticated = session != nil
            case .signedOut:
                currentUser = nil
                isAuthenticated = false
            default:
                break
            }
        }
    }

    func signInWithEmail(email: String, password: String) async throws {
        let session = try await client.signIn(email: email, password: password)
        currentUser = session.user
        isAuthenticated = true
    }

    func signUpWithEmail(email: String, password: String) async throws {
        let response = try await client.signUp(email: email, password: password)
        if let session = response.session {
            currentUser = session.user
            isAuthenticated = true
        }
    }

    func resetPassword(email: String) async throws {
        try await client.resetPasswordForEmail(email)
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidToken
        }

        let session = try await client.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idTokenString
            )
        )
        currentUser = session.user

        if let fullName = credential.fullName?.formatted(), !fullName.isEmpty {
            _ = try? await client.update(user: UserAttributes(data: ["full_name": .string(fullName)]))
        }

        isAuthenticated = true
    }

    func signInWithGoogle() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.noPresenter
        }

        let clientID = Config.EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.invalidToken
        }

        let session = try await client.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
        )
        currentUser = session.user
        isAuthenticated = true
    }

    func signOut() async throws {
        try await client.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    func deleteAccount() async throws {
        let supabaseURL = AppConfig.supabaseURL
        let supabaseKey = AppConfig.supabaseAnonKey

        guard let session = try? await client.session else {
            throw AuthError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: "\(supabaseURL)/functions/v1/delete-user")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.deletionFailed
        }

        try await signOut()
    }

    var userEmail: String? {
        currentUser?.email
    }

    var userDisplayName: String? {
        if let data = currentUser?.userMetadata,
           let name = data["full_name"]?.stringValue {
            return name
        }
        return nil
    }
}

nonisolated enum AuthError: LocalizedError, Sendable {
    case invalidToken
    case noPresenter
    case notAuthenticated
    case deletionFailed

    var errorDescription: String? {
        switch self {
        case .invalidToken: return "Could not retrieve authentication token."
        case .noPresenter: return "Unable to present sign-in screen."
        case .notAuthenticated: return "You are not signed in."
        case .deletionFailed: return "Failed to delete account. Please try again."
        }
    }
}

nonisolated extension AnyJSON {
    var stringValue: String? {
        switch self {
        case .string(let value): return value
        default: return nil
        }
    }
}
