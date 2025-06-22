import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct RecommendationsView: View {
    @State private var listener: ListenerRegistration?
    @State private var recommendations: [Recommendation] = []
    @State private var showSendView = false
    @State private var localVotes: [String: Bool?] = [:]

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
                                handleVoteToggle(rec: rec, value: true)
                            }) {
                                Image(systemName: currentVote(for: rec) == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    .font(.title2)
                                    .foregroundColor(currentVote(for: rec) == true ? .blue : .gray)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: {
                                handleVoteToggle(rec: rec, value: false)
                            }) {
                                Image(systemName: currentVote(for: rec) == false ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                    .font(.title2)
                                    .foregroundColor(currentVote(for: rec) == false ? .red : .gray)
                            }
                            .buttonStyle(PlainButtonStyle())
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
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }

                var updated: [Recommendation] = []

                for doc in docs {
                    do {
                        var rec = try doc.data(as: Recommendation.self)
                        rec.id = doc.documentID
                        updated.append(rec)
                        localVotes[rec.id ?? ""] = rec.vote
                    } catch {
                        // Optional: log decode errors in development
                    }
                }

                recommendations = updated
            }
    }

    func handleVoteToggle(rec: Recommendation, value: Bool) {
        guard let recID = rec.id else { return }
        let ref = Firestore.firestore().collection("recommendations").document(recID)

        let currentVote = localVotes[recID] ?? rec.vote
        let newVote: Bool? = (currentVote == value) ? nil : value
        localVotes[recID] = newVote

        switch newVote {
        case .some(let vote):
            ref.updateData(["vote": vote])
        case .none:
            ref.updateData(["vote": FieldValue.delete()])
        }
    }

    func currentVote(for rec: Recommendation) -> Bool? {
        localVotes[rec.id ?? ""] ?? rec.vote
    }
}
