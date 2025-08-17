import SwiftUI

struct RecommendationDetailView: View {
    @StateObject private var viewModel: RecommendationDetailViewModel
    @State private var selectedPrefill: Recommendation? = nil

    init(recommendation: Recommendation) {
        _viewModel = StateObject(wrappedValue: RecommendationDetailViewModel(recommendation: recommendation))
    }

    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RecommendationBaseDetailView(
                        viewModel: viewModel,
                        titlePrefix: "From @",
                        editableVote: viewModel.isRecipient,
                        editableNote: viewModel.isRecipient
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }

            Button(action: {
                selectedPrefill = viewModel.recommendation
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
            viewModel.recommendation.fromUsername.map { "From @\($0)" } ?? "Recommendation"
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedPrefill) { rec in
            SendRecommendationView(prefilledRecommendation: rec)
        }
        .onAppear { viewModel.markViewedIfNeeded() }
    }
}
        
