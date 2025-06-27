import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FriendSearchView: View {
    @State private var searchEmail = ""
    @State private var message = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TextField("Enter friend's email address", text: $searchEmail)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                Button(action: sendFriendRequestByEmail) {
                    Text("Send Friend Request")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
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

    func sendFriendRequestByEmail() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }

        let searchEmailLower = searchEmail.lowercased()
        let db = Firestore.firestore()

        db.collection("users")
            .whereField("emailLowercase", isEqualTo: searchEmailLower)
            .getDocuments { snapshot, error in
                guard let doc = snapshot?.documents.first else {
                    // Don't reveal anything – always show the same message
                    message = "If the email is registered, your request has been sent."
                    return
                }

                let targetUID = doc.documentID

                // Prevent sending request to self
                if targetUID == myUID {
                    message = "You can't send a friend request to yourself."
                    return
                }

                let myRef = db.collection("users").document(myUID)
                let targetRef = db.collection("users").document(targetUID)

                // Send the friend request
                myRef.updateData([
                    "sentRequests": FieldValue.arrayUnion([targetUID])
                ])

                targetRef.updateData([
                    "friendRequests": FieldValue.arrayUnion([myUID])
                ])

                message = "That user will receive your friend request if they are registered."
            }
    }
}
