import AuthenticationServices
import Combine
import CryptoKit
import Foundation
import SwiftUI

enum AuthStatus { case unknown, signedOut, signingIn, signedIn, error }

@MainActor
final class AuthController: NSObject, ObservableObject {
    @Published var status: AuthStatus = .unknown
    @Published var errorMessage: String?

    private let storage = AuthStorage.shared

    var session: AuthStorage.Session? { storage.session }

    func bootstrap() {
        status = storage.session == nil ? .signedOut : .signedIn
    }

    /// Dev-only: create a local preview session without any auth server.
    func signInAsDev() {
        let user = UserInfo(
            id: "00000000-0000-0000-0000-000000000000",
            email: "preview@twende.local",
            full_name: "Preview Traveler",
            role: "traveler",
            phone: nil
        )
        storage.write(
            user: user,
            access: "dev-bypass-access-token",
            refresh: "dev-bypass-refresh-token"
        )
        status = .signedIn
    }

    func signInWithBaseIdP() async {
        status = .signingIn
        errorMessage = nil
        do {
            let verifier = Self.randomURLSafeString(length: 48)
            let challenge = Self.s256Challenge(verifier)
            let stateParam = UUID().uuidString

            var components = URLComponents(
                url: APIConfig.idpIssuer.appendingPathComponent("oauth2/authorize"),
                resolvingAgainstBaseURL: false
            )!
            components.queryItems = [
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "client_id", value: APIConfig.idpClientID),
                URLQueryItem(name: "redirect_uri", value: APIConfig.mobileRedirectURI),
                URLQueryItem(name: "scope", value: "openid profile"),
                URLQueryItem(name: "state", value: stateParam),
                URLQueryItem(name: "code_challenge", value: challenge),
                URLQueryItem(name: "code_challenge_method", value: "S256"),
            ]
            guard let authURL = components.url else {
                throw APIError.invalidURL
            }

            let callback = try await runWebAuth(url: authURL)
            guard let cb = URLComponents(url: callback, resolvingAgainstBaseURL: false),
                  let code = cb.queryItems?.first(where: { $0.name == "code" })?.value,
                  let returnedState = cb.queryItems?.first(where: { $0.name == "state" })?.value
            else { throw APIError.http(0, "Missing code in callback") }
            guard returnedState == stateParam else {
                throw APIError.http(0, "State mismatch")
            }

            struct ExchangeBody: Encodable {
                let code: String
                let code_verifier: String
                let redirect_uri: String
            }
            let resp: AuthResponse = try await APIClient.shared.post(
                "auth/idp-exchange",
                body: ExchangeBody(
                    code: code,
                    code_verifier: verifier,
                    redirect_uri: APIConfig.mobileRedirectURI
                )
            )
            storage.write(user: resp.user, access: resp.access_token, refresh: resp.refresh_token)
            status = .signedIn
        } catch {
            errorMessage = error.localizedDescription
            status = .error
        }
    }

    /// Dev fallback so the app is testable without registering this client in IdP.
    func signInWithEmail(email: String, password: String) async {
        status = .signingIn
        errorMessage = nil
        do {
            struct LoginBody: Encodable {
                let email: String
                let password: String
            }
            let resp: AuthResponse = try await APIClient.shared.post(
                "auth/login",
                body: LoginBody(email: email, password: password)
            )
            storage.write(user: resp.user, access: resp.access_token, refresh: resp.refresh_token)
            status = .signedIn
        } catch {
            errorMessage = error.localizedDescription
            status = .error
        }
    }

    func signOut() {
        storage.clear()
        status = .signedOut
    }

    // MARK: - PKCE helpers

    private static func randomURLSafeString(length: Int) -> String {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        var rng = SystemRandomNumberGenerator()
        return String((0..<length).map { _ in alphabet[Int(rng.next() % UInt64(alphabet.count))] })
    }

    private static func s256Challenge(_ verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncoded()
    }

    // MARK: - ASWebAuthenticationSession bridge

    private func runWebAuth(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: APIConfig.mobileRedirectScheme
            ) { callback, error in
                if let error = error {
                    cont.resume(throwing: error)
                } else if let callback = callback {
                    cont.resume(returning: callback)
                } else {
                    cont.resume(throwing: APIError.http(0, "No callback"))
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            if !session.start() {
                cont.resume(throwing: APIError.http(0, "Failed to start auth session"))
            }
        }
    }
}

extension AuthController: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Find the foreground active window scene.
        DispatchQueue.main.sync {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first(where: { $0.activationState == .foregroundActive })?
                .windows
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}

private extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
