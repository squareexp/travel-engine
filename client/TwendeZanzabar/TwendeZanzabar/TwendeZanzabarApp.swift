import SwiftUI

@main
struct TwendeZanzabarApp: App {
    @StateObject private var auth = AuthController()

    var body: some Scene {
        WindowGroup {
            Group {
                switch auth.status {
                case .unknown:
                    SplashView()
                case .signedIn:
                    RootShell()
                default:
                    SignInView()
                }
            }
            .environmentObject(auth)
            .task { auth.bootstrap() }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            TwendeColor.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "globe.europe.africa.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(TwendeColor.primary)
                BrandHeader(subtitle: "One App. Zanzibar & Tanzania.",
                            fontSize: 28)
            }
        }
    }
}
