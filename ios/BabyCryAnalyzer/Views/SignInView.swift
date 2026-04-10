import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct SignInView: View {
    var authService: AuthService
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    @State private var showCreateAccount: Bool = false
    @State private var showResetPassword: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)

                    Image(systemName: "waveform.circle")
                        .font(.system(size: 64, weight: .thin))
                        .foregroundStyle(.white)

                    Spacer().frame(height: 16)

                    Text("CrySense")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Understand your baby's needs")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))

                    Spacer().frame(height: 40)

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
                                .textContentType(.password)
                                .padding(14)
                                .background(.white.opacity(0.08))
                                .clipShape(.rect(cornerRadius: 10))
                                .foregroundStyle(.white)
                        }

                        Button {
                            Task { await signInWithEmail() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.black)
                                } else {
                                    Text("Sign In")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(.white)
                            .foregroundStyle(.black)
                            .clipShape(.rect(cornerRadius: 12))
                        }
                        .disabled(email.isEmpty || password.isEmpty || isLoading)
                        .opacity(email.isEmpty || password.isEmpty ? 0.5 : 1)

                        Button {
                            showResetPassword = true
                        } label: {
                            Text("Forgot password?")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.4))
                        }
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
                        SignInWithAppleButton(.signIn) { request in
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
                                Text("Sign in with Google")
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

                    Spacer().frame(height: 32)

                    Button {
                        showCreateAccount = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundStyle(.white.opacity(0.4))
                            Text("Create one")
                                .foregroundStyle(.white.opacity(0.7))
                                .fontWeight(.semibold)
                        }
                        .font(.footnote)
                    }

                    Spacer().frame(height: 40)
                }
            }
            .scrollIndicators(.hidden)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
        .sheet(isPresented: $showCreateAccount) {
            CreateAccountView(authService: authService)
        }
        .sheet(isPresented: $showResetPassword) {
            ResetPasswordView(authService: authService)
        }
    }

    private func signInWithEmail() async {
        isLoading = true
        do {
            try await authService.signInWithEmail(email: email, password: password)
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
        } catch let error as GIDSignInError where error.code == .canceled {
            return
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
