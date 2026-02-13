// Channeled/Views/SignInView.swift
import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "tv")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Channeled")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your personal TV guide")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                if isLoading {
                    ProgressView("Signing in...")
                } else {
                    Button(action: signIn) {
                        HStack {
                            Image(systemName: "applelogo")
                            Text("Continue with Apple")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()
            Spacer()
        }
        .padding()
    }

    private func signIn() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let credential = try await AuthService.shared.signInWithApple()
                // Send to backend and store token
                dismiss()
            } catch {
                errorMessage = "Sign in failed. Please try again."
                isLoading = false
            }
        }
    }
}

#Preview {
    SignInView()
}
