//
//  RecommendationsView.swift
//  Recky
//
//  Created by Paul Winters on 6/20/25.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct RecommendationsView: View {
    @State private var listener: ListenerRegistration?
    @State private var recommendations: [Recommendation] = []
    @State private var showSendView = false

    var body: some View {
        VStack {
            if recommendations.isEmpty {
                Text("No recommendations yet.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(recommendations) { rec in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(rec.title)
                            .font(.headline)

                        Text("Type: \(rec.type)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let notes = rec.notes, !notes.isEmpty {
                            Text("“\(notes)”")
                                .font(.body)
                                .italic()
                        }

                        HStack(spacing: 12) {
                            Button(action: {
                                vote(on: rec, value: true)
                            }) {
                                Text(rec.vote == true ? "👍🏼" : "👍🏻")
                                    .font(.title2)
                            }

                            Button(action: {
                                vote(on: rec, value: false)
                            }) {
                                Text(rec.vote == false ? "👎🏼" : "👎🏻")
                                    .font(.title2)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Recommendations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showSendView = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            startListeningForRecommendations()
        }
        .onDisappear {
            listener?.remove()
            listener = nil
        }
        .sheet(isPresented: $showSendView) {
            SendRecommendationView()
        }
    }

    func startListeningForRecommendations() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }

        listener = Firestore.firestore().collection("recommendations")
            .whereField("toUID", isEqualTo: myUID)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Failed to listen to recommendations: \(error)")
                    return
                }

                guard let docs = snapshot?.documents else { return }

                self.recommendations = docs.compactMap { doc in
                    try? doc.data(as: Recommendation.self)
                }
            }
    }

    func vote(on rec: Recommendation, value: Bool) {
        guard let recID = rec.id else { return }
        let ref = Firestore.firestore().collection("recommendations").document(recID)

        let newVote: Bool? = (rec.vote == value) ? nil : value
        print("Voting on \(rec.title) (\(recID)): \(String(describing: newVote))")

        if let vote = newVote {
            ref.updateData(["vote": vote]) { error in
                if let error = error {
                    print("Vote failed: \(error)")
                }
            }
        } else {
            ref.updateData(["vote": FieldValue.delete()]) { error in
                if let error = error {
                    print("Vote removal failed: \(error)")
                }
            }
        }
    }
}
