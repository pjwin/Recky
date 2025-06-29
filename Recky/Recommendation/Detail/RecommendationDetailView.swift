import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct RecommendationDetailView: View {
    var recommendation: Recommendation
    @State private var voteNoteText: String = ""
    @State private var selectedPrefill: Recommendation? = nil

    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    let isRecipient = recommendation.toUID == Auth.auth().currentUser?.uid

                    RecommendationBaseDetailView(
                        recommendation: recommendation,
                        titlePrefix: "From @",
                        editableVote: isRecipient,
                        editableNote: isRecipient
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }

            Button(action: {
                selectedPrefill = recommendation
            }) {
                HStack {
                    Spacer()
                    Label("Recommend This", systemImage: "plus")
                    Spacer()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .navigationTitle(
            recommendation.fromUsername.map { "From @\($0)" } ?? "Recommendation"
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedPrefill) { rec in
            SendRecommendationView(prefilledRecommendation: rec)
        }
        .onAppear {
            if let note = recommendation.voteNote {
                voteNoteText = note
            }
            if recommendation.toUID == Auth.auth().currentUser?.uid,
               !(recommendation.hasBeenViewedByRecipient ?? false),
               let id = recommendation.id {
                markAsViewed(id)
            }
        }
    }


    func markAsViewed(_ recommendationID: String) {
        let ref = Firestore.firestore().collection("recommendations").document(recommendationID)
        ref.updateData(["hasBeenViewedByRecipient": true])
    }

    private func saveVoteNote() {
        guard let id = recommendation.id else { return }
        let ref = Firestore.firestore().collection("recommendations").document(id)
        ref.updateData(["voteNote": voteNoteText]) { error in
            if let error = error {
                print("Failed to save note: \(error)")
            }
        }
    }
}
