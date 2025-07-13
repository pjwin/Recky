import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isSigningUp = false
    @State private var didSendVerification = false
    @State private var isResending = false
    @State private var resendMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if !didSendVerification {
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

                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)

                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }

                        Button(action: signUp) {
                            Text(isSigningUp ? "Creating Account..." : "Create Account")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(isSigningUp || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                    } else {
                        Text("A verification link has been sent to:")
                        Text(email)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)

                        Text("Please check your inbox and click the link to verify your email address.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)

                        if let resendMessage = resendMessage {
                            Text(resendMessage)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Button(action: resendVerificationEmail) {
                            Text(isResending ? "Resending..." : "Resend Verification Email")
                                .font(.subheadline)
                        }
                        .disabled(isResending)
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(didSendVerification) // block exit until verified
                }
            }
        }
    }

    private func signUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        isSigningUp = true
        errorMessage = nil

        AuthManager.shared.signUp(email: email, password: password) { error in
            isSigningUp = false
            if let error = error {
                errorMessage = error
            } else {
                sendVerificationEmail()
            }
        }
    }

    private func sendVerificationEmail() {
        if let user = Auth.auth().currentUser {
            user.sendEmailVerification { error in
                if let error = error {
                    errorMessage = "Could not send verification email: \(error.localizedDescription)"
                } else {
                    didSendVerification = true
                }
            }
        }
    }

    private func resendVerificationEmail() {
        isResending = true
        resendMessage = nil

        if let user = Auth.auth().currentUser {
            user.sendEmailVerification { error in
                isResending = false
                if let error = error {
                    resendMessage = "Error: \(error.localizedDescription)"
                } else {
                    resendMessage = "Verification email sent again to \(user.email ?? "")"
                }
            }
        }
    }
}
