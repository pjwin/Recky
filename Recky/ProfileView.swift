import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: SessionManager
    @State private var pendingRequestCount: Int = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("👤 Profile")
                    .font(.largeTitle)
                    .bold()

                if let email = session.user?.email {
                    Text("Signed in as: \(email)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                NavigationLink(destination: FriendsPageView()) {
                    HStack {
                        Spacer()
                        Image(systemName: "person.2")

                        ZStack(alignment: .topTrailing) {
                            Text("Manage Friends")
                                .font(.body)

                            if pendingRequestCount > 0 {
                                Text("\(pendingRequestCount)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 12, y: -10)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }

                Button("Sign Out") {
                    session.signOut()
                }
                .foregroundColor(.red)
                .padding(.top, 30)

                Spacer()

                Button("Close") {
                    dismiss()
                }
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                listenForFriendRequests()
            }
        }
    }

    func listenForFriendRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid)
            .addSnapshotListener { docSnapshot, error in
                guard let doc = docSnapshot, let data = doc.data() else {
                    return
                }
                let requests = data["friendRequests"] as? [String] ?? []
                pendingRequestCount = requests.count
            }
    }

}
