import FirebaseAuth
import SwiftUI

struct SendRecommendationView: View {
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var type = RecommendationType.movie.rawValue
    @State private var notes = ""

    @State private var usernameQuery = ""
    @State private var searchResults: [(uid: String, username: String)] = []
    @State private var selectedFriend: (uid: String, username: String)? = nil

    @State private var message = ""

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

                    Button("Send Recommendation") {
                        sendRecommendation()
                    }
                    .disabled(title.isEmpty || selectedFriend == nil)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        title.isEmpty || selectedFriend == nil ? Color.gray : Color.blue
                    )
                    .foregroundColor(.white)
                    .cornerRadius(8)

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

            if !searchResults.isEmpty && selectedFriend == nil {
                ForEach(searchResults, id: \.uid) { user in
                    Button {
                        selectedFriend = user
                        usernameQuery = user.username
                        searchResults = []
                    } label: {
                        Text(user.username)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            if let friend = selectedFriend {
                Text("Sending to: \(friend.username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }

    private func searchUsernames() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }

        RecommendationService.shared.searchUsers(query: usernameQuery, excludeUID: myUID) { results in
            searchResults = results
        }
    }

    private func sendRecommendation() {
        guard let fromUID = Auth.auth().currentUser?.uid,
              let friend = selectedFriend else { return }

        let rec = Recommendation(
            id: nil,
            fromUID: fromUID,
            toUID: friend.uid,
            title: title,
            type: type,
            notes: notes.isEmpty ? nil : notes,
            timestamp: Date(), // Will be replaced in Firestore anyway
            vote: nil,
            fromUsername: nil
        )

        RecommendationService.shared.send(rec) { result in
            switch result {
            case .success:
                message = "Recommendation sent!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            case .failure(let error):
                message = "Failed to send: \(error.localizedDescription)"
            }
        }
    }
}
