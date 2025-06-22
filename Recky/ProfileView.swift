//
//  ProfileView.swift
//  Recky
//
//  Created by Paul Winters on 6/21/25.
//


import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        VStack(spacing: 20) {
            Text("Profile")
                .font(.largeTitle)
                .bold()

            if let email = session.user?.email {
                Text("Signed in as:")
                    .font(.headline)
                Text(email)
                    .foregroundColor(.gray)
            }

            Button("Log Out") {
                session.signOut()
            }
            .foregroundColor(.red)

            Spacer()
        }
        .padding()
    }
}
