//
//  HomeView.swift
//  Recky
//
//  Created by Paul Winters on 6/17/25.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        VStack(spacing: 16) {
            Text("You're logged in to Recky! 🎉")
                .font(.title)

            if let email = session.user?.email {
                Text("Signed in as:")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text(email)
                    .font(.headline)
            }
            
            Divider()

            FriendsListView() // ⬅️ Inline view here

            Spacer()

            Button("Sign Out") {
                session.signOut()
            }
            .padding()
            .foregroundColor(.red)
        }
        .padding()
    }
}
