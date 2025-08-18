import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: SessionManager
    @State private var pendingRequestCount: Int = 0
    @State private var myStats: DetailedStats? = nil

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
                    
                    Button("Sign Out") {
                        session.signOut()
                    }
                    .foregroundColor(.red)
                    
                    Divider()
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

                if let stats = myStats {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recommendations Sent:")
                                .font(.body)
                                .foregroundColor(.gray)

                            statRow(icon: "👍", label: "Thumbs Up", count: stats.sentThumbsUp, percentage: stats.sentUpPercentage)
                            statRow(icon: "👎", label: "Thumbs Down", count: stats.sentThumbsDown, percentage: stats.sentDownPercentage)
                            statRow(icon: "❓", label: "No Vote", count: stats.sentNoVote, percentage: stats.sentNoVotePercentage)
                            statRow(icon: "📦", label: "Total Sent", count: stats.sentTotal)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recommendations Received:")
                                .font(.body)
                                .foregroundColor(.gray)

                            statRow(icon: "👍", label: "Thumbs Up", count: stats.receivedThumbsUp, percentage: stats.receivedUpPercentage)
                            statRow(icon: "👎", label: "Thumbs Down", count: stats.receivedThumbsDown, percentage: stats.receivedDownPercentage)
                            statRow(icon: "❓", label: "No Vote", count: stats.receivedNoVote, percentage: stats.receivedNoVotePercentage)
                            statRow(icon: "📥", label: "Total Received", count: stats.receivedTotal)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    Text("Loading your stats...")
                        .font(.body)
                        .foregroundColor(.gray)
                }

                Spacer()

                Button("Close") {
                    dismiss()
                }
                .padding(.bottom)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                listenForFriendRequests()
                fetchMyStats()
            }
        }
    }
    
    @ViewBuilder
    func statRow(icon: String, label: String, count: Int, percentage: String? = nil) -> some View {
        HStack {
            HStack {
                Text(icon)
                Text(label)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(count)")
                .frame(width: 40, alignment: .trailing)

            if let pct = percentage {
                Text("(\(pct))")
                    .foregroundColor(.gray)
                    .frame(width: 60, alignment: .trailing)
            }
        }
        .font(.body)
    }

    func listenForFriendRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid)
            .addSnapshotListener { docSnapshot, error in
                guard let doc = docSnapshot, let data = doc.data() else {
                    return
                }
                let requests = data["friendRequests"] as? [[String: Any]] ?? []
                pendingRequestCount = requests.count
            }
    }

    func fetchMyStats() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task {
            do {
                let stats = try await RecommendationStatsService.fetchDetailedStats(for: uid)
                await MainActor.run {
                    myStats = stats
                }
            } catch {
                await MainActor.run { myStats = nil }
            }
        }
    }
}
