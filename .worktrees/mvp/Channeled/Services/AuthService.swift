// Channeled/Services/AuthService.swift
import Foundation
import AuthenticationServices
import CryptoKit

final class AuthService: NSObject {
    static let shared = AuthService()

    private var currentNonce: String?
    private var continuation: CheckedContinuation<AppleCredential, Error>?

    private override init() {}

    func signInWithApple() async throws -> AppleCredential {
        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.performRequests()
        }
    }
}

extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AuthError.invalidCredential)
            continuation = nil
            return
        }

        let credential = AppleCredential(
            userID: appleIDCredential.user,
            email: appleIDCredential.email,
            fullName: appleIDCredential.fullName,
            identityToken: appleIDCredential.identityToken,
            authorizationCode: appleIDCredential.authorizationCode
        )

        continuation?.resume(returning: credential)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

struct AppleCredential {
    let userID: String
    let email: String?
    let fullName: PersonNameComponents?
    let identityToken: Data?
    let authorizationCode: Data?
}

enum AuthError: Error {
    case invalidCredential
}

// MARK: - Nonce helpers
private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        let randoms: [UInt8] = (0..<16).map { _ in
            var random: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            return random
        }

        for random in randoms {
            if random < UInt8(charset.count) {
                result.append(charset[Int(random)])
                remainingLength -= 1
                if remainingLength == 0 {
                    break
                }
            }
        }
    }

    return result
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    return hashedData.compactMap {
        String(format: "%02x", $0)
    }.joined()
}
