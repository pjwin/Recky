import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var session: SessionManager
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var showSignUp = false


    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                logo
                welcomeText
                emailPasswordFields
                googleSignInButton
                signUpButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 80)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var logo: some View {
        Image("AppLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 120, height: 120)
            .padding(.top, 40)
    }

    private var welcomeText: some View {
        Text("Welcome to Recky")
            .font(.title)
            .fontWeight(.semibold)
    }

    private var emailPasswordFields: some View {
        VStack(spacing: 12) {
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button("Log In", action: login)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }

    private var googleSignInButton: some View {
        VStack(spacing: 16) {
            Text("or")
                .font(.subheadline)
                .foregroundColor(.gray)

            Button(action: googleLogin) {
                HStack {
                    Image("GoogleLogo")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("Sign in with Google")
                        .foregroundColor(.black)
                        .fontWeight(.medium)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(8)
            }
        }
    }

    private var signUpButton: some View {
        Button("Sign Up with Email") {
            showSignUp = true
        }
        .foregroundColor(.blue)
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
    }

    private func login() {
        AuthManager.shared.login(email: email, password: password) { error in
            errorMessage = error
        }
    }

    private func signUp() {
        AuthManager.shared.signUp(email: email, password: password) { error in
            errorMessage = error
        }
    }

    private func googleLogin() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            errorMessage = "No root view controller found"
            return
        }

        AuthManager.shared.handleGoogleSignIn(presenting: rootVC) { error in
            errorMessage = error
        }
    }
}
