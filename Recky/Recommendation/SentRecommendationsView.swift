//
//  SentRecommendationsView.swift
//  Recky
//
//  Created by Paul Winters on 6/27/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SentRecommendationsView: View {
    @State private var sentRecommendations: [Recommendation] = []
    
    var body: some View {
        List {
            if sentRecommendations.isEmpty {
                Text("You haven't sent any recommendations yet.")
                    .foregroundColor(.gray)
            } else {
                ForEach(sentRecommendations) { rec in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(EmojiUtils.forType(rec.type)) \(rec.title)")
                            .font(.headline)

                        HStack {
                            Text("to @\(rec.toUID)")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Spacer()

                            voteStatus(for: rec.vote)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Sent Recommendations")
        .onAppear {
            loadSentRecommendations()
        }
    }

    private func loadSentRecommendations() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("recommendations")
            .whereField("fromUID", isEqualTo: myUID)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching sent recommendations: \(error)")
                    return
                }

                var temp: [Recommendation] = []
                let group = DispatchGroup()

                for doc in snapshot?.documents ?? [] {
                    if var rec = try? doc.data(as: Recommendation.self) {
                        rec.id = doc.documentID
                        group.enter()

                        db.collection("users").document(rec.toUID).getDocument { userDoc, _ in
                            let username = userDoc?.get("username") as? String ?? "unknown"
                            rec.fromUsername = username // optional: use for logging
                            temp.append(rec)
                            group.leave()
                        }
                    }
                }

                group.notify(queue: .main) {
                    self.sentRecommendations = temp
                }
            }
    }

    private func voteStatus(for vote: Bool?) -> some View {
        if let vote = vote {
            if vote {
                return AnyView(
                    Label("Liked", systemImage: "hand.thumbsup.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                )
            } else {
                return AnyView(
                    Label("Disliked", systemImage: "hand.thumbsdown.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                )
            }
        } else {
            return AnyView(
                Text("No vote yet")
                    .foregroundColor(.gray)
                    .font(.caption)
            )
        }
    }
}
