import FirebaseAuth
import SwiftUI

struct SendRecommendationView: View {
    @Environment(\.dismiss) var dismiss
    var prefilledRecommendation: Recommendation? = nil

    @State private var title = ""
    @State private var type = RecommendationType.movie.rawValue
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

                    Picker("Type", selection: $type) {
                        ForEach(RecommendationType.allCases, id: \.rawValue) { type in
                            Text(type.displayName).tag(type.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

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
                    if rec.type.isEmpty == false { type = rec.type }
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

        FriendService.shared.searchFriends(query: usernameQuery, currentUID: myUID) { results in
            searchResults = results
        }
    }

    private func sendRecommendation() {
        guard let fromUID = Auth.auth().currentUser?.uid else { return }
        isSending = true

        let timestamp = Date()
        let group = DispatchGroup()

        for friend in selectedFriends {
            let rec = Recommendation(
                id: nil,
                fromUID: fromUID,
                toUID: friend.uid,
                title: title,
                type: type,
                notes: notes.isEmpty ? nil : notes,
                timestamp: timestamp,
                vote: nil,
                fromUsername: CurrentUserSession.shared.username, // or fetch from user model
                toUsername: friend.username,
            )

            group.enter()
            RecommendationService.shared.send(rec) { _ in
                group.leave()
            }
        }

        group.notify(queue: .main) {
            message = "Recommendations sent!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }
}
