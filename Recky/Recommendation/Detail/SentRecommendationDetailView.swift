import SwiftUI

struct SentRecommendationDetailView: View {
    @StateObject private var viewModel: RecommendationDetailViewModel

    init(recommendation: Recommendation) {
        _viewModel = StateObject(wrappedValue: RecommendationDetailViewModel(recommendation: recommendation))
    }

    var body: some View {
        RecommendationBaseDetailView(
            viewModel: viewModel,
            titlePrefix: "To @",
            editableVote: false,
            editableNote: false
        )
        .navigationTitle(
            viewModel.recommendation.toUsername.map { "To @\($0)" } ?? "Sent Recommendation"
        )
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.markViewedIfNeeded() }
    }
}
