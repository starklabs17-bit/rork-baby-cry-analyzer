import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit

@MainActor
@Observable
class AuthService {
    var isAuthenticated: Bool = false
    var currentUserID: String? = nil
    var isLoading: Bool = false
    var isCheckingSession: Bool = true
    var errorMessage: String? = nil
    var isDeletingAccount: Bool = false

    private var currentNonce: String?

    init() {
        Task {
            await checkSession()
        }
    }

    private func checkSession() async {
        defer {
            isCheckingSession = false
        }

        let session = try? await supabase.auth.session

        if session != nil {
            isAuthenticated = true
            currentUserID = session?.user.id.uuidString
        } else {
            isAuthenticated = false
            currentUserID = nil
        }
    }

    func signUp(email: String, password: String) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, trimmedEmail.contains("@") else {
            errorMessage = "Please enter a valid email address."
            return
        }

        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.signUp(email: trimmedEmail, password: password)
            isAuthenticated = true
            currentUserID = supabase.auth.currentUser?.id.uuidString
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.signIn(email: trimmedEmail, password: password)
            isAuthenticated = true
            currentUserID = supabase.auth.currentUser?.id.uuidString
        } catch {
            errorMessage = "Incorrect email or password."
        }
    }

    func signOut() async {
        try? await supabase.auth.signOut()
        isAuthenticated = false
        currentUserID = nil
    }

    var currentUserEmail: String? {
        supabase.auth.currentUser?.email
    }

    func resetPassword(email: String) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.resetPasswordForEmail(trimmedEmail)
            errorMessage = "Password reset email sent. Check your inbox."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }

    var hashedNonce: String? {
        guard let nonce = currentNonce else { return nil }
        return sha256(nonce)
    }

    func signInWithApple(idToken: String, fullName: PersonNameComponents?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken
                )
            )

            if let fullName, let formatted = PersonNameComponentsFormatter.localizedString(from: fullName, style: .default).nilIfEmpty {
                _ = try? await supabase.auth.update(
                    user: UserAttributes(data: ["full_name": .string(formatted)])
                )
            }

            isAuthenticated = true
            currentUserID = supabase.auth.currentUser?.id.uuidString
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signInWithGoogle() async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await supabase.auth.signInWithOAuth(
                provider: .google
            ) { (session: ASWebAuthenticationSession) in
                session.prefersEphemeralWebBrowserSession = false
            }
            isAuthenticated = true
            currentUserID = supabase.auth.currentUser?.id.uuidString
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAccount() async -> Bool {
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            let functions = supabase.functions
            _ = try await functions.invoke("delete-user")
            try? await supabase.auth.signOut()
            isAuthenticated = false
            currentUserID = nil
            return true
        } catch {
            try? await supabase.auth.signOut()
            isAuthenticated = false
            currentUserID = nil
            return true
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
