import SwiftUI

struct SentRecommendationDetailView: View {
    var recommendation: Recommendation

    var body: some View {
        RecommendationBaseDetailView(
            recommendation: recommendation,
            titlePrefix: "To @",
            editableVote: false
        )
        .navigationTitle(recommendation.toUsername.map { "To @\($0)" } ?? "Sent Recommendation")
        .navigationBarTitleDisplayMode(.inline)
    }
}
