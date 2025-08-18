import FirebaseAuth
import SwiftUI

struct FriendsPageView: View {
    @State private var friends: [Friend] = []
    @State private var requestCount = 0
    @State private var showRequests = false
    @State private var showFriendSearch = false
    @State private var isEditing = false
    @State private var refreshTrigger = false
    @State private var friendStatsByUID: [String: FriendStats] = [:]
    private let service = FriendService.shared

    var body: some View {
        VStack(alignment: .leading) {
            HeaderView()
            Divider()
            FriendListView()
        }
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(isEditing ? "Done" : "Edit") {
            isEditing.toggle()
        })
        .onAppear {
            loadRequests()
            loadFriends()
        }
        .onChange(of: refreshTrigger) {
            loadFriends()
            loadRequests()
        }
        .sheet(isPresented: $showRequests) {
            NavigationView {
                FriendRequestsView(onFriendAccepted: {
                    refreshTrigger.toggle()
                })
                .navigationTitle("Friend Requests")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            showRequests = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showFriendSearch) {
            NavigationView {
                FriendSearchView()
                    .navigationTitle("Add Friend")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showFriendSearch = false
                            }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func HeaderView() -> some View {
        HStack {
            Button(action: { showRequests = true }) {
                HStack(spacing: 4) {
                    Label("Requests", systemImage: "person.crop.circle.badge.questionmark")
                    if requestCount > 0 {
                        Text("(\(requestCount))")
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Button(action: { showFriendSearch = true }) {
                Label("Add Friend", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }

    @ViewBuilder
    private func FriendListView() -> some View {
        List {
            if friends.isEmpty {
                Text("No friends yet �")
                    .foregroundColor(.gray)
            } else {
                ForEach(friends) { friend in
                    FriendRow(friend: friend)
                }
            }
        }
    }

    @ViewBuilder
    private func FriendRow(friend: Friend) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(friend.username)
                Spacer()
                if isEditing {
                    Button {
                        removeFriend(friend)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }

            if let stats = friendStatsByUID[friend.id] {
                HStack {
                    Text("Sent:")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(stats.sentText)
                        .font(.caption2)
                        .foregroundColor(.green)

                    Spacer()

                    Text("Received:")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(stats.receivedText)
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            } else {
                Text("Loading stats...")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }

    private func loadRequests() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        Task {
            do {
                let requests = try await service.fetchFriendRequests(for: myUID)
                await MainActor.run { requestCount = requests.count }
            } catch {
                await MainActor.run { requestCount = 0 }
            }
        }
    }

    private func loadFriends() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        Task {
            do {
                let loadedFriends = try await service.fetchFriends(for: myUID)
                await MainActor.run { self.friends = loadedFriends }

                await withTaskGroup(of: (String, FriendStats)?.self) { group in
                    for friend in loadedFriends {
                        group.addTask {
                            do {
                                let stats = try await RecommendationStatsService.fetchStats(for: friend.id)
                                return (friend.id, stats)
                            } catch {
                                return nil
                            }
                        }
                    }

                    var results: [String: FriendStats] = [:]
                    for await result in group {
                        if let (id, stats) = result {
                            results[id] = stats
                        }
                    }
                    await MainActor.run {
                        friendStatsByUID = results
                    }
                }
            } catch {
                await MainActor.run { self.friends = [] }
            }
        }
    }

    private func removeFriend(_ friend: Friend) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        Task {
            do {
                try await service.removeFriend(friend.id, currentUID: myUID)
                await MainActor.run {
                    friends.removeAll { $0.id == friend.id }
                }
            } catch {
                // Ignore error
            }
        }
    }
}
