import SwiftUI

struct ProfileView: View {
    var store: StoreViewModel
    var authService: AuthService
    @Environment(CryHistoryStore.self) private var historyStore
    @State private var showPaywall: Bool = false
    @State private var showPrivacy: Bool = false
    @State private var showTerms: Bool = false
    @State private var showSupport: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showSignOutConfirmation: Bool = false
    @State private var isDeleting: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false

    private let privacyURL = URL(string: "https://crysense.app/privacy")!
    private let termsURL = URL(string: "https://crysense.app/terms")!
    private let supportURL = URL(string: "https://crysense.app/support")!

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 52, height: 52)
                            Image(systemName: "person.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.accentColor)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(authService.userDisplayName ?? "CrySense User")
                                .font(.subheadline.bold())
                            if let email = authService.userEmail {
                                Text(email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(store.isPremium ? "Pro Member" : "Free Plan")
                                .font(.caption)
                                .foregroundStyle(store.isPremium ? .green : .secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                if !store.isPremium {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Upgrade to Pro")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                    Text("Unlimited analyses & full history")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                Section("Your Stats") {
                    LabeledContent("Total Analyses", value: "\(historyStore.analyses.count)")
                    LabeledContent("This Week", value: "\(historyStore.analysesThisWeek)")
                    LabeledContent("Most Common", value: historyStore.mostCommonReason)
                }

                if store.isPremium {
                    Section("Subscription") {
                        LabeledContent("Status", value: "Active")
                            .foregroundStyle(.green)
                        Button("Manage Subscription") {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }

                Section("Legal") {
                    Button {
                        showPrivacy = true
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    .foregroundStyle(.primary)

                    Button {
                        showTerms = true
                    } label: {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                    }
                    .foregroundStyle(.primary)

                    Button {
                        showSupport = true
                    } label: {
                        Label("Support", systemImage: "questionmark.circle.fill")
                    }
                    .foregroundStyle(.primary)
                }

                Section("Account") {
                    Button {
                        showSignOutConfirmation = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .foregroundStyle(.primary)

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label {
                            if isDeleting {
                                Text("Deleting...")
                            } else {
                                Text("Delete Account")
                            }
                        } icon: {
                            Image(systemName: "trash.fill")
                        }
                    }
                    .disabled(isDeleting)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(store: store)
        }
        .sheet(isPresented: $showPrivacy) {
            LegalWebView(title: "Privacy Policy", url: privacyURL)
        }
        .sheet(isPresented: $showTerms) {
            LegalWebView(title: "Terms of Service", url: termsURL)
        }
        .sheet(isPresented: $showSupport) {
            LegalWebView(title: "Support", url: supportURL)
        }
        .alert("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                Task {
                    try? await authService.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        do {
            try await authService.deleteAccount()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isDeleting = false
    }
}
