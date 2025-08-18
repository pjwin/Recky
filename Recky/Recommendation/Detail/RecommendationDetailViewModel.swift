import FirebaseAuth
import Foundation

@MainActor
class RecommendationDetailViewModel: ObservableObject {
    @Published var recommendation: Recommendation
    private let repository = RecommendationRepository.shared

    init(recommendation: Recommendation) {
        self.recommendation = recommendation
    }

    var isRecipient: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return recommendation.toUID == uid
    }

    func markViewedIfNeeded() {
        guard isRecipient,
              !(recommendation.hasBeenViewedByRecipient ?? false),
              let id = recommendation.id else { return }
        Task {
            try? await repository.markViewed(id: id)
            recommendation.hasBeenViewedByRecipient = true
        }
    }

    func toggleVote(_ newVote: Bool) {
        guard isRecipient, let id = recommendation.id else { return }
        let previousVote = recommendation.vote
        let nextVote: Bool? = (recommendation.vote == newVote) ? nil : newVote
        recommendation.vote = nextVote
        Task {
            do {
                try await repository.vote(recommendationID: id, vote: nextVote)
                if let vote = nextVote {
                    var updated = recommendation
                    updated.vote = vote
                    try await RecommendationStatsService.updateStatsInFirestore(for: updated, change: .increment)
                    if let previous = previousVote, previous != vote {
                        var previousRec = recommendation
                        previousRec.vote = previous
                        try await RecommendationStatsService.updateStatsInFirestore(for: previousRec, change: .decrement)
                    }
                } else if let previous = previousVote {
                    var previousRec = recommendation
                    previousRec.vote = previous
                    try await RecommendationStatsService.updateStatsInFirestore(for: previousRec, change: .decrement)
                }
            } catch {
                print("Failed to update vote: \(error)")
                recommendation.vote = previousVote
            }
        }
    }

    func saveVoteNote(_ note: String) {
        guard isRecipient, let id = recommendation.id else { return }
        Task {
            do {
                try await repository.saveVoteNote(id: id, note: note)
                recommendation.voteNote = note
            } catch {
                print("Failed to save note: \(error)")
            }
        }
    }
}

