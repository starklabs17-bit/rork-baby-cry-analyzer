import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct CreateAccountView: View {
    var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    @State private var showConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 40)

                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 48, weight: .thin))
                            .foregroundStyle(.white)

                        Spacer().frame(height: 16)

                        Text("Create Account")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Start understanding your baby")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))

                        Spacer().frame(height: 32)

                        VStack(spacing: 16) {
                            VStack(spacing: 12) {
                                TextField("Email", text: $email)
                                    .textContentType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .padding(14)
                                    .background(.white.opacity(0.08))
                                    .clipShape(.rect(cornerRadius: 10))
                                    .foregroundStyle(.white)

                                SecureField("Password", text: $password)
                                    .textContentType(.newPassword)
                                    .padding(14)
                                    .background(.white.opacity(0.08))
                                    .clipShape(.rect(cornerRadius: 10))
                                    .foregroundStyle(.white)

                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .padding(14)
                                    .background(.white.opacity(0.08))
                                    .clipShape(.rect(cornerRadius: 10))
                                    .foregroundStyle(.white)
                            }

                            Button {
                                Task { await createAccount() }
                            } label: {
                                Group {
                                    if isLoading {
                                        ProgressView().tint(.black)
                                    } else {
                                        Text("Create Account")
                                            .font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(.white)
                                .foregroundStyle(.black)
                                .clipShape(.rect(cornerRadius: 12))
                            }
                            .disabled(!isFormValid || isLoading)
                            .opacity(!isFormValid ? 0.5 : 1)
                        }
                        .padding(20)
                        .background(.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.1), lineWidth: 0.5)
                        )
                        .clipShape(.rect(cornerRadius: 16))
                        .padding(.horizontal, 24)

                        Spacer().frame(height: 24)

                        HStack(spacing: 12) {
                            Rectangle().frame(height: 0.5).foregroundStyle(.white.opacity(0.15))
                            Text("or").font(.caption).foregroundStyle(.white.opacity(0.3))
                            Rectangle().frame(height: 0.5).foregroundStyle(.white.opacity(0.15))
                        }
                        .padding(.horizontal, 40)

                        Spacer().frame(height: 24)

                        VStack(spacing: 12) {
                            SignInWithAppleButton(.signUp) { request in
                                request.requestedScopes = [.email, .fullName]
                            } onCompletion: { result in
                                handleAppleSignIn(result: result)
                            }
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 50)
                            .clipShape(.rect(cornerRadius: 12))

                            Button {
                                Task { await signInWithGoogle() }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "g.circle.fill")
                                        .font(.title3)
                                    Text("Sign up with Google")
                                        .font(.subheadline.bold())
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(.white.opacity(0.08))
                                .foregroundStyle(.white)
                                .clipShape(.rect(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.white.opacity(0.15), lineWidth: 0.5)
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer().frame(height: 40)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
        .alert("Check Your Email", isPresented: $showConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text("We sent a confirmation link to \(email). Please verify your email to sign in.")
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && password == confirmPassword && password.count >= 6
    }

    private func createAccount() async {
        isLoading = true
        do {
            try await authService.signUpWithEmail(email: email, password: password)
            if !authService.isAuthenticated {
                showConfirmation = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    private func handleAppleSignIn(result: Result<ASAuthorization, any Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
            Task {
                do {
                    try await authService.signInWithApple(credential: credential)
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func signInWithGoogle() async {
        do {
            try await authService.signInWithGoogle()
            dismiss()
        } catch let error as GIDSignInError where error.code == .canceled {
            return
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
