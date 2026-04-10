import SwiftUI

struct ResetPasswordView: View {
    var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
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
                        Spacer().frame(height: 60)

                        Image(systemName: "key.fill")
                            .font(.system(size: 48, weight: .thin))
                            .foregroundStyle(.white)

                        Spacer().frame(height: 16)

                        Text("Reset Password")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)

                        Text("We'll send you a reset link")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))

                        Spacer().frame(height: 32)

                        VStack(spacing: 16) {
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .padding(14)
                                .background(.white.opacity(0.08))
                                .clipShape(.rect(cornerRadius: 10))
                                .foregroundStyle(.white)

                            Button {
                                Task { await resetPassword() }
                            } label: {
                                Group {
                                    if isLoading {
                                        ProgressView().tint(.black)
                                    } else {
                                        Text("Send Reset Link")
                                            .font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(.white)
                                .foregroundStyle(.black)
                                .clipShape(.rect(cornerRadius: 12))
                            }
                            .disabled(email.isEmpty || isLoading)
                            .opacity(email.isEmpty ? 0.5 : 1)
                        }
                        .padding(20)
                        .background(.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.1), lineWidth: 0.5)
                        )
                        .clipShape(.rect(cornerRadius: 16))
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
        .alert("Email Sent", isPresented: $showConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text("Check your email for a password reset link.")
        }
    }

    private func resetPassword() async {
        isLoading = true
        do {
            try await authService.resetPassword(email: email)
            showConfirmation = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}
