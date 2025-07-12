import FirebaseFirestore
import SwiftUI

struct RecommendationBaseDetailView: View {
    var recommendation: Recommendation
    var titlePrefix: String
    var editableVote: Bool
    var editableNote: Bool
    @State private var currentVote: Bool?
    @State private var voteNoteText: String = ""
    @State private var originalNoteText: String = ""
    @FocusState private var isNoteFocused: Bool

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
                        Image(
                            systemName: currentVote == true
                                ? "hand.thumbsup.fill" : "hand.thumbsup"
                        )
                        .font(.title2)
                        .foregroundColor(currentVote == true ? .blue : .gray)
                    }

                    Button(action: { toggleVote(false) }) {
                        Image(
                            systemName: currentVote == false
                                ? "hand.thumbsdown.fill" : "hand.thumbsdown"
                        )
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

            if editableNote {
                VStack(alignment: .leading, spacing: 12) {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            .background(Color.white)
                            .frame(minHeight: 100)

                        TextEditor(text: $voteNoteText)
                            .focused($isNoteFocused)
                            .padding(8)
                            .frame(minHeight: 100, maxHeight: 120)
                            .background(Color.clear)
                            .cornerRadius(10)

                        if voteNoteText.isEmpty {
                            Text("Share your thoughts about this...")
                                .foregroundColor(.gray)
                                .padding(14)
                                .allowsHitTesting(false)
                        }
                    }

                    Text("\(voteNoteText.count)/250")
                        .font(.caption)
                        .foregroundColor(
                            voteNoteText.count > 250 ? .red : .gray
                        )
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    if voteNoteText != originalNoteText {
                        HStack {
                            Spacer()
                            Button("Save Note") {
                                saveVoteNote()
                            }
                            .disabled(
                                voteNoteText.trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                ).isEmpty || voteNoteText.count > 250
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                            Spacer()
                        }
                        .transition(.opacity.combined(with: .scale))
                        .animation(
                            .easeInOut(duration: 0.2),
                            value: voteNoteText
                        )
                    }
                }
            } else if let note = recommendation.voteNote, !note.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("They wrote:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("“\(note)”")
                        .italic()
                        .padding(8)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            currentVote = recommendation.vote
            voteNoteText = recommendation.voteNote ?? ""
            originalNoteText = voteNoteText
        }
    }

    private func toggleVote(_ newVote: Bool) {
        guard editableVote, let recID = recommendation.id else { return }

        let ref = Firestore.firestore().collection("recommendations").document(
            recID
        )
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

    private func saveVoteNote() {
        guard let id = recommendation.id else { return }
        isNoteFocused = false

        let ref = Firestore.firestore().collection("recommendations").document(id)
        ref.updateData(["voteNote": voteNoteText]) { error in
            if error == nil {
                withAnimation {
                    originalNoteText = voteNoteText
                }
            } else {
                print("Failed to save note: \(error!)")
            }
        }
    }
}
