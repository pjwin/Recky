import FirebaseAuth
import SwiftUI

struct SendRecommendationView: View {
    @Environment(\.dismiss) var dismiss
    var prefilledRecommendation: Recommendation? = nil

    @State private var title = ""
    @State private var tagsText = ""
    @State private var notes = ""

    @State private var usernameQuery = ""
    @State private var searchResults: [(uid: String, username: String)] = []
    @State private var selectedFriends: [(uid: String, username: String)] = []

    @State private var message = ""
    @State private var isSending = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    TextField("What are you recommending?", text: $title)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    TextField("Tags (comma-separated)", text: $tagsText)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    TextField("Optional notes...", text: $notes)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    usernameInputSection

                    Button(action: {
                        sendRecommendation()
                    }) {
                        Text(isSending ? "Sending..." : "Send Recommendation")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background((title.isEmpty || selectedFriends.isEmpty || isSending) ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(title.isEmpty || selectedFriends.isEmpty || isSending)

                    if !message.isEmpty {
                        Text(message)
                            .foregroundColor(.green)
                    }
                }
                .padding()
            }
            .navigationTitle("New Recommendation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let rec = prefilledRecommendation {
                    if title.isEmpty { title = rec.title }
                    if notes.isEmpty, let recNotes = rec.notes { notes = recNotes }
                    if tagsText.isEmpty { tagsText = rec.tags.joined(separator: ", ") }
                }
            }
        }
    }

    private var usernameInputSection: some View {
        VStack(alignment: .leading) {
            TextField("Send to username...", text: $usernameQuery)
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .onChange(of: usernameQuery) {
                    searchUsernames()
                }

            if !searchResults.isEmpty {
                ForEach(searchResults, id: \.uid) { user in
                    Button {
                        guard !selectedFriends.contains(where: { $0.uid == user.uid }) else { return }
                        selectedFriends.append(user)
                        usernameQuery = ""
                        searchResults = []
                    } label: {
                        Text(user.username)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            if !selectedFriends.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sending to:")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    ForEach(selectedFriends, id: \.uid) { friend in
                        HStack {
                            Text(friend.username)
                            Spacer()
                            Button(action: {
                                selectedFriends.removeAll { $0.uid == friend.uid }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private func searchUsernames() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        Task {
            do {
                let results = try await FriendService.shared.searchFriends(query: usernameQuery, currentUID: myUID)
                await MainActor.run { searchResults = results }
            } catch {
                await MainActor.run { searchResults = [] }
            }
        }
    }

    private func sendRecommendation() {
        guard let fromUID = Auth.auth().currentUser?.uid else { return }
        isSending = true

        let timestamp = Date()
        Task {
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for friend in selectedFriends {
                        let tags = tagsText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        let rec = Recommendation(
                            id: nil,
                            fromUID: fromUID,
                            toUID: friend.uid,
                            title: title,
                            tags: tags,
                            notes: notes.isEmpty ? nil : notes,
                            timestamp: timestamp,
                            vote: nil,
                            voteNote: nil,
                            fromUsername: CurrentUserSession.shared.username,
                            toUsername: friend.username
                        )

                        group.addTask {
                            try await RecommendationService.shared.send(rec)
                        }
                    }
                    try await group.waitForAll()
                }

                await MainActor.run {
                    message = "Recommendations sent!"
                    isSending = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    message = "Failed to send recommendations"
                    isSending = false
                }
            }
        }
    }
}
