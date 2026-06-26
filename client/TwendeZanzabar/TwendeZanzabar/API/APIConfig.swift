import Foundation

enum APIConfig {
    /// Twende backend. iOS Simulator/device reaches host via localhost.
    static let backendBaseURL = URL(string: "http://localhost:8090/api/v1")!

    /// Base-IdP issuer.
    static let idpIssuer = URL(string: "http://localhost:8080")!

    static let idpClientID = "sq_live_twende_1b1i4f6j"

    /// Mobile redirect — registered with the IdP. Matches CFBundleURLScheme.
    static let mobileRedirectURI = "twende://auth/callback"
    static let mobileRedirectScheme = "twende"

    /// When true, the app bypasses IdP/login and uses a local "preview"
    /// session so the design/flow can be reviewed without a working auth
    /// server. Flip to false before shipping.
    static let devBypassAuth = true
}
