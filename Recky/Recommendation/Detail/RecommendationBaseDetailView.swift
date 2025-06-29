//
//  RecommendationDetailContentView.swift
//  Recky
//
//  Created by Paul Winters on 6/28/25.
//
import SwiftUI
import FirebaseFirestore

struct RecommendationBaseDetailView: View {
    var recommendation: Recommendation
    var titlePrefix: String
    var editableVote: Bool

    @State private var currentVote: Bool?

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

            if editableVote {
                HStack(spacing: 20) {
                    Button(action: { toggleVote(true) }) {
                        Image(systemName: currentVote == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.title2)
                            .foregroundColor(currentVote == true ? .blue : .gray)
                    }

                    Button(action: { toggleVote(false) }) {
                        Image(systemName: currentVote == false ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.title2)
                            .foregroundColor(currentVote == false ? .red : .gray)
                    }
                }
                .padding(.top, 8)
                .buttonStyle(PlainButtonStyle())
            } else {
                voteIcon(for: recommendation.vote)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            currentVote = recommendation.vote
        }
    }

    private func toggleVote(_ newVote: Bool) {
        guard editableVote, let recID = recommendation.id else { return }

        let ref = Firestore.firestore().collection("recommendations").document(recID)
        let nextVote: Bool? = (currentVote == newVote) ? nil : newVote
        currentVote = nextVote

        if let vote = nextVote {
            ref.updateData(["vote": vote])
        } else {
            ref.updateData(["vote": FieldValue.delete()])
        }
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
