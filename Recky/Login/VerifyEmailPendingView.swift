import SwiftUI
import FirebaseAuth

struct VerifyEmailPendingView: View {
    @EnvironmentObject var session: SessionManager
    @State private var isResending = false
    @State private var resendMessage: String?
    @State private var refreshMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                Text("Verification Needed")
                    .font(.title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Image(systemName: "envelope.badge")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.blue)

                Text("We’ve sent a verification link to your email.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Text("Haven’t received the link? Check your spam folder, or click Resend.")
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.horizontal)

                if let resendMessage = resendMessage {
                    Text(resendMessage)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                if let refreshMessage = refreshMessage {
                    Text(refreshMessage)
                        .font(.footnote)
                        .foregroundColor(.green)
                }

                Button("Resend Verification Email") {
                    resendVerificationEmail()
                }
                .disabled(isResending)

                Button("Check Again") {
                    refreshVerificationStatus()
                }

                Button("Sign Out") {
                    session.signOut()
                }
                .foregroundColor(.red)

                Spacer()
            }
            .padding()
        }
    }

    private func resendVerificationEmail() {
        guard let user = Auth.auth().currentUser else { return }
        isResending = true
        resendMessage = nil

        user.sendEmailVerification { error in
            isResending = false
            if let error = error {
                resendMessage = "Error: \(error.localizedDescription)"
            } else {
                resendMessage = "Verification email sent again to \(user.email ?? "")"
            }
        }
    }

    private func refreshVerificationStatus() {
        guard let user = Auth.auth().currentUser else { return }

        user.reload { error in
            if let error = error {
                refreshMessage = "Could not refresh: \(error.localizedDescription)"
            } else if user.isEmailVerified {
                session.user = user
                session.isVerified = true
            } else {
                refreshMessage = "Still not verified"
            }
        }
    }
}
