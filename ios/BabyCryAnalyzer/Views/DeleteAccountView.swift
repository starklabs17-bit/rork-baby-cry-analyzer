import SwiftUI

struct DeleteAccountView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var confirmText: String = ""
    @State private var showFinalConfirmation: Bool = false

    private let confirmationWord = "DELETE"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.red)

                        Text("Delete Your Account")
                            .font(.title3.bold())

                        Text("This action is permanent and cannot be undone. All your data, including cry history, preferences, and subscription information will be permanently removed.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }

                Section("What will be deleted") {
                    Label("Your account and profile", systemImage: "person.crop.circle.badge.minus")
                    Label("All cry analysis history", systemImage: "waveform.badge.minus")
                    Label("Saved preferences and settings", systemImage: "gearshape.fill")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type **\(confirmationWord)** to confirm")
                            .font(.subheadline)
                        TextField("Type \(confirmationWord)", text: $confirmText)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showFinalConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            if authService.isDeletingAccount {
                                ProgressView()
                            } else {
                                Text("Permanently Delete Account")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(confirmText != confirmationWord || authService.isDeletingAccount)
                }
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Are you absolutely sure?", isPresented: $showFinalConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Forever", role: .destructive) {
                    Task {
                        let success = await authService.deleteAccount()
                        if success { dismiss() }
                    }
                }
            } message: {
                Text("Your account and all associated data will be permanently deleted. This cannot be undone.")
            }
        }
    }
}
