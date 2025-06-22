import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RecommendationDetailView: View {
    var recommendation: Recommendation

    @State private var currentVote: Bool?

    var body: some View {
        VStack(spacing: 20) {
            Text(timestampFormatted(recommendation.timestamp))
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(emojiForType(recommendation.type))
                .font(.largeTitle)
            
            Text(recommendation.title)
                .font(.largeTitle)
                .bold()

            if let notes = recommendation.notes, !notes.isEmpty {
                Text("“\(notes)”")
                    .italic()
                    .padding()
            }

            HStack(spacing: 20) {
                Button(action: {
                    toggleVote(true)
                }) {
                    Image(systemName: currentVote == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.title2)
                        .foregroundColor(currentVote == true ? .blue : .gray)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    toggleVote(false)
                }) {
                    Image(systemName: currentVote == false ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .font(.title2)
                        .foregroundColor(currentVote == false ? .red : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
        .navigationTitle(recommendation.fromUsername.map { "From @\($0)" } ?? "Recommendation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            currentVote = recommendation.vote
        }
    }

    private func toggleVote(_ newVote: Bool) {
        guard let recID = recommendation.id else { return }
        let ref = Firestore.firestore().collection("recommendations").document(recID)

        let nextVote: Bool? = (currentVote == newVote) ? nil : newVote
        currentVote = nextVote

        if let vote = nextVote {
            ref.updateData(["vote": vote])
        } else {
            ref.updateData(["vote": FieldValue.delete()])
        }
    }

    
    func timestampFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func emojiForType(_ type: String) -> String {
        switch type.lowercased() {
        case "movie": return "🎬"
        case "tv": return "📺"
        case "book": return "📚"
        case "album": return "🎧"
        case "game": return "🎮"
        default: return "❓"
        }
    }
}
