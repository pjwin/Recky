import FirebaseCore
import SwiftUI
import GoogleSignIn

@main
struct ReckyApp: App {
    @StateObject var session = SessionManager()
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if let _ = session.user {
                if session.isVerified {
                    HomeView()
                        .environmentObject(session)
                } else {
                    VerifyEmailPendingView()
                        .environmentObject(session)
                }
            } else {
                LoginView()
                    .environmentObject(session)
            }
        }
    }
}
