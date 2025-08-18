import SwiftUI

struct FriendRequestsView: View {
    @StateObject private var viewModel = FriendRequestsViewModel()
    var onFriendAccepted: () -> Void = {}

    var body: some View {
        VStack {
            List(viewModel.requests, id: \.uid) { request in
                VStack(spacing: 8) {
                    Text(request.username)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack(spacing: 24) {
                        Button("Accept") {
                            viewModel.acceptRequest(uid: request.uid, username: request.username) {
                                onFriendAccepted()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)

                        Button("Ignore") {
                            viewModel.ignoreRequest(uid: request.uid, username: request.username)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                .padding(.horizontal)
            }
        }
        .onAppear(perform: viewModel.loadRequests)
    }
}
