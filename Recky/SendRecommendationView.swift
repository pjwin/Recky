//
//  SendRecommendationView.swift
//  Recky
//
//  Created by Paul Winters on 6/20/25.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct SendRecommendationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var type = "movie"
    @State private var notes = ""

    @State private var usernameQuery = ""
    @State private var searchResults: [(uid: String, username: String)] = []
    @State private var selectedFriend: (uid: String, username: String)? = nil

    @State private var message = ""
    let types = ["movie", "book", "album", "tv", "game"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    TextField("What are you recommending?", text: $title)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    Picker("Type", selection: $type) {
                        ForEach(types, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    TextField("Optional notes...", text: $notes)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    VStack(alignment: .leading) {
                        TextField("Send to username...", text: $usernameQuery)
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .onChange(of: usernameQuery) {
                                searchUsernames()
                            }

                        if !searchResults.isEmpty && selectedFriend == nil {
                            ForEach(searchResults, id: \.uid) { user in
                                Button {
                                    selectedFriend = user
                                    usernameQuery = user.username
                                    searchResults = []
                                } label: {
                                    Text(user.username)
                                        .padding(.vertical, 4)
                                        .frame(
                                            maxWidth: .infinity,
                                            alignment: .leading
                                        )
                                }
                            }
                        }

                        if let friend = selectedFriend {
                            Text("Sending to: \(friend.username)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }

                    Button("Send Recommendation") {
                        sendRecommendation()
                    }
                    .disabled(title.isEmpty || selectedFriend == nil)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        title.isEmpty || selectedFriend == nil
                            ? Color.gray : Color.blue
                    )
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    if !message.isEmpty {
                        Text(message)
                            .foregroundColor(.green)
                    }
                }
                .padding()
            }
            .navigationTitle("New Recommendation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    func searchUsernames() {
        guard !usernameQuery.isEmpty else {
            searchResults = []
            return
        }

        Firestore.firestore().collection("users")
            .whereField("username", isGreaterThanOrEqualTo: usernameQuery)
            .whereField("username", isLessThan: usernameQuery + "\u{f8ff}")
            .limit(to: 5)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Firestore error: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }

                searchResults = documents.compactMap { doc in
                    let uid = doc.documentID
                    let username = doc.get("username") as? String ?? ""
                    guard uid != Auth.auth().currentUser?.uid else {
                        return nil
                    }
                    return (uid: uid, username: username)
                }

            }
    }

    func sendRecommendation() {
        guard let myUID = Auth.auth().currentUser?.uid,
            let friend = selectedFriend
        else { return }

        let rec = Recommendation(
            fromUID: myUID,
            toUID: friend.uid,
            type: type,
            title: title,
            notes: notes,
            timestamp: Date(),
            vote: nil
        )

        do {
            try Firestore.firestore().collection("recommendations")
                .addDocument(from: rec)
            message = "Recommendation sent!"
            // Optionally auto-dismiss:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            message = "Failed to send."
        }
    }
}
