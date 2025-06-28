import SwiftUI

struct SentRecommendationDetailView: View {
    var recommendation: Recommendation

    var body: some View {
        VStack(spacing: 20) {
            Text(timestampFormatted(recommendation.timestamp))
                .font(.caption)
                .foregroundColor(.gray)

            Text(EmojiUtils.forType(recommendation.type))
                .font(.largeTitle)

            Text(recommendation.title)
                .font(.largeTitle)
                .bold()

            if let notes = recommendation.notes, !notes.isEmpty {
                Text("“\(notes)”")
                    .italic()
                    .padding()
            }

            voteIcon(for: recommendation.vote)
                .padding(.top, 8)

            Spacer()
        }
        .padding()
        .navigationTitle(recommendation.toUsername.map { "To @\($0)" } ?? "Sent Recommendation")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func timestampFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func voteIcon(for vote: Bool?) -> some View {
        Group {
            switch vote {
            case .some(true):
                Image(systemName: "hand.thumbsup.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            case .some(false):
                Image(systemName: "hand.thumbsdown.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            case .none:
                EmptyView()
            @unknown default:
                EmptyView()
            }
        }
    }
}
