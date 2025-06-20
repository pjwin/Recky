import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FriendSearchView: View {
    @State private var searchUsername = ""
    @State private var foundUser: (uid: String, username: String)? = nil
    @State private var message = ""
    @State private var isAlreadyFriend = false
    @State private var hasSentRequest = false
    @State private var hasIncomingRequest = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TextField("Search by username", text: $searchUsername)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                Button(action: searchUser) {
                    Text("Search")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                if let user = foundUser {
                    VStack(spacing: 8) {
                        Text("Found: \(user.username)")
                            .font(.headline)

                        if isAlreadyFriend {
                            Text("You're already friends 👯‍♀️")
                                .foregroundColor(.green)
                        } else if hasSentRequest {
                            Text("Friend request already sent ✅")
                                .foregroundColor(.gray)
                        } else if hasIncomingRequest {
                            Text("They've sent you a request! Check pending requests.")
                                .foregroundColor(.orange)
                        } else {
                            Button("Send Friend Request") {
                                sendFriendRequest(to: user.uid)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.top)
                }

                if !message.isEmpty {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Add Friend")
        .navigationBarTitleDisplayMode(.inline)
    }

    func searchUser() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users")
            .whereField("username", isEqualTo: searchUsername)
            .getDocuments { snapshot, error in
                if let error = error {
                    message = "Error: \(error.localizedDescription)"
                    return
                }
                guard let doc = snapshot?.documents.first else {
                    message = "User not found"
                    foundUser = nil
                    return
                }

                let uid = doc.documentID
                let username = doc.get("username") as? String ?? "Unknown"
                foundUser = (uid, username)
                message = ""

                db.collection("users").document(myUID).getDocument { myDoc, _ in
                    guard let myData = myDoc?.data() else { return }

                    let myFriends = myData["friends"] as? [String] ?? []
                    let mySent = myData["sentRequests"] as? [String] ?? []
                    let myReceived = myData["friendRequests"] as? [String] ?? []

                    isAlreadyFriend = myFriends.contains(uid)
                    hasSentRequest = mySent.contains(uid)
                    hasIncomingRequest = myReceived.contains(uid)
                }
            }
    }

    func sendFriendRequest(to targetUID: String) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let myRef = db.collection("users").document(myUID)
        let targetRef = db.collection("users").document(targetUID)

        myRef.updateData([
            "sentRequests": FieldValue.arrayUnion([targetUID])
        ])

        targetRef.updateData([
            "friendRequests": FieldValue.arrayUnion([myUID])
        ])

        message = "Request sent!"
    }
}
