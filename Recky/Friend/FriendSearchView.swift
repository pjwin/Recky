import SwiftUI

struct FriendSearchView: View {
    @StateObject private var viewModel = FriendSearchViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TextField("Enter friend's email address", text: $viewModel.searchEmail)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                Button(action: viewModel.sendFriendRequestByEmail) {
                    Text("Send Friend Request")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                if !viewModel.message.isEmpty {
                    Text(viewModel.message)
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
}
