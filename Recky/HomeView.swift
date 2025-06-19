//
//  HomeView.swift
//  Recky
//
//  Created by Paul Winters on 6/17/25.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: SessionManager
    @State private var pendingRequestCount: Int = 0


    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("You're logged in to Recky! 🎉")
                    .font(.title)

                if let email = session.user?.email {
                    Text("Signed in as: \(email)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Divider()

                NavigationLink(destination: FriendsPageView()) {
                    Text("Friends")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Spacer()

                Button("Sign Out") {
                    session.signOut()
                }
                .foregroundColor(.red)
            }
            .padding()
            .navigationTitle("Home")
            .onAppear {
                startListeningForFriendRequests()
            }
        }
    }
    
    func startListeningForFriendRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(uid).addSnapshotListener { docSnapshot, error in
            guard let doc = docSnapshot, let data = doc.data() else { return }
            let requests = data["friendRequests"] as? [String] ?? []
            pendingRequestCount = requests.count
        }
    }
}
