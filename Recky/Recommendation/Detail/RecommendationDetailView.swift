import SwiftUI

struct RecommendationDetailView: View {
    var recommendation: Recommendation

    var body: some View {
        RecommendationBaseDetailView(
            recommendation: recommendation,
            titlePrefix: "From @",
            editableVote: true
        )
        .navigationTitle(recommendation.fromUsername.map { "From @\($0)" } ?? "Recommendation")
        .navigationBarTitleDisplayMode(.inline)
    }
}
