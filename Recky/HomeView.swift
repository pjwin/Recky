import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: SessionManager

    @State private var recommendations: [Recommendation] = []
    @State private var sentRecommendations: [Recommendation] = []

    @State private var showSendView = false
    @State private var showProfile = false
    @State private var showAllRecommendations = false
    @State private var showAllSent = false
    @State private var pendingRequestCount: Int = 0
    @AppStorage("hasPulledToRefresh") private var hasPulledToRefresh = false

    @State private var isLatestExpanded = true
    @State private var isSentExpanded = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                headerBar

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        latestRecommendationsSection
                        sentRecommendationsSection
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    loadRecommendations()
                    loadSentRecommendations()
                    hasPulledToRefresh = true
                }

                recommendButton
            }
            .padding()
            .sheet(isPresented: $showSendView) {
                SendRecommendationView()
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .navigationDestination(isPresented: $showAllRecommendations) {
                AllRecommendationsView()
            }
            .navigationDestination(isPresented: $showAllSent) {
                SentRecommendationsView()
            }
            .onAppear {
                loadRecommendations()
                loadSentRecommendations()
                startListeningForFriendRequests()
            }
        }
    }

    // MARK: Header Bar

    private var headerBar: some View {
        ZStack {
            HStack {
                Image("AppLogo")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Spacer()

                ZStack(alignment: .topTrailing) {
                    Button(action: {
                        showProfile = true
                    }) {
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(width: 28, height: 28)
                    }

                    if pendingRequestCount > 0 {
                        Text("\(pendingRequestCount)")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 10, y: -10)
                    }
                }
            }

            VStack(spacing: 2) {
                Text("Welcome back,")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                if let email = session.user?.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: Latest Recommendations

    private var latestRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: {
                    isLatestExpanded.toggle()
                }) {
                    HStack {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isLatestExpanded ? 90 : 0))
                            .animation(.easeInOut(duration: 0.2), value: isLatestExpanded)
                        Text("Latest Recommendations")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }

                Spacer()

                Button("See All >") {
                    showAllRecommendations = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }

            if isLatestExpanded {
                if recommendations.isEmpty {
                    Text("No recent recommendations.")
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                } else {
                    VStack(spacing: 12) {
                        if !hasPulledToRefresh {
                            Text("Pull down to refresh")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        ForEach(Array(recommendations.prefix(5))) { rec in
                            NavigationLink(destination: RecommendationDetailView(recommendation: rec)) {
                                recommendationRow(for: rec)
                            }
                        }
                    }
                    .padding(.top)
                }
            }
        }
    }

    // MARK: Sent Recommendations

    private var sentRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: {
                    isSentExpanded.toggle()
                }) {
                    HStack {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isSentExpanded ? 90 : 0))
                            .animation(.easeInOut(duration: 0.2), value: isSentExpanded)
                        Text("Sent Recommendations")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }

                Spacer()

                Button("See All >") {
                    showAllSent = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }

            if isSentExpanded {
                if sentRecommendations.isEmpty {
                    Text("You haven't sent any yet.")
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(sentRecommendations.prefix(5))) { rec in
                            NavigationLink(destination: ReadOnlyRecommendationView(recommendation: rec)) {
                                sentRecommendationRow(for: rec)
                            }
                        }
                    }
                    .padding(.top)
                }
            }
        }
    }

    // MARK: Recommendation Row

    private func recommendationRow(for rec: Recommendation) -> some View {
        let hasVoted = rec.vote != nil
        let typeEmoji = EmojiUtils.forType(rec.type)
        let voteIconName: String? = {
            switch rec.vote {
            case true: return "hand.thumbsup.fill"
            case false: return "hand.thumbsdown.fill"
            default: return nil
            }
        }()

        return HStack(alignment: .top, spacing: 12) {
            Group {
                if let iconName = voteIconName {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(rec.vote == true ? .blue : .red)
                } else {
                    Color.clear
                        .frame(width: 22, height: 22)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text("\(typeEmoji) \(rec.title)")
                        .font(.body)
                        .lineLimit(1)

                    Spacer()

                    if !hasVoted {
                        Text("NEW")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(4)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }

                Text("from @\(rec.fromUsername ?? "unknown")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .overlay(
            !hasVoted ?
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                : nil
        )
    }

    private func sentRecommendationRow(for rec: Recommendation) -> some View {
        let typeEmoji = EmojiUtils.forType(rec.type)
        let hasVote = rec.vote != nil

        let voteIconName: String? = {
            switch rec.vote {
            case true: return "hand.thumbsup.fill"
            case false: return "hand.thumbsdown.fill"
            default: return nil
            }
        }()

        return HStack(alignment: .top, spacing: 12) {
            Group {
                if let iconName = voteIconName {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(rec.vote == true ? .blue : .red)
                } else {
                    Color.clear
                        .frame(width: 22, height: 22)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(typeEmoji) \(rec.title)")
                    .font(.body)
                    .lineLimit(1)

                Text("to @\(rec.toUsername ?? "unknown")")
                    .font(.caption)
                    .foregroundColor(.gray)

                voteStatus(for: rec.vote)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .overlay(
            !hasVote
                ? RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                : nil
        )
    }

    private func voteStatus(for vote: Bool?) -> some View {
        Group {
            switch vote {
            case true:
                Label("Liked", systemImage: "hand.thumbsup.fill")
                    .foregroundColor(.blue)
            case false:
                Label("Disliked", systemImage: "hand.thumbsdown.fill")
                    .foregroundColor(.red)
            default:
                Text("No vote yet")
                    .foregroundColor(.gray)
            }
        }
        .font(.caption)
    }

    // MARK: Recommend Button

    private var recommendButton: some View {
        Button(action: {
            showSendView = true
        }) {
            HStack {
                Spacer()
                Label("Recommend Something", systemImage: "plus")
                Spacer()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }

    // MARK: Data Load

    private func loadRecommendations() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("recommendations")
            .whereField("toUID", isEqualTo: myUID)
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                guard error == nil else { return }
                let docs = snapshot?.documents ?? []
                var results: [Int: Recommendation] = [:]
                let group = DispatchGroup()

                for (index, doc) in docs.enumerated() {
                    if var rec = try? doc.data(as: Recommendation.self) {
                        rec.id = doc.documentID
                        group.enter()
                        db.collection("users").document(rec.fromUID).getDocument { userDoc, _ in
                            rec.fromUsername = userDoc?.get("username") as? String ?? "unknown"
                            results[index] = rec
                            group.leave()
                        }
                    }
                }

                group.notify(queue: .main) {
                    self.recommendations = (0..<docs.count).compactMap { results[$0] }
                }
            }
    }

    private func loadSentRecommendations() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()

        db.collection("recommendations")
            .whereField("fromUID", isEqualTo: myUID)
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to fetch sent recommendations: \(error)")
                    return
                }

                let docs = snapshot?.documents ?? []
                var results: [Int: Recommendation] = [:]
                let group = DispatchGroup()

                for (index, doc) in docs.enumerated() {
                    if var rec = try? doc.data(as: Recommendation.self) {
                        rec.id = doc.documentID
                        group.enter()

                        db.collection("users").document(rec.toUID).getDocument { userDoc, _ in
                            let username = userDoc?.get("username") as? String ?? "unknown"
                            rec.toUsername = username
                            results[index] = rec
                            group.leave()
                        }
                    }
                }

                group.notify(queue: .main) {
                    self.sentRecommendations = (0..<docs.count).compactMap { results[$0] }
                }
            }
    }

    // MARK: Friend Request Listener

    func startListeningForFriendRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").document(uid)
            .addSnapshotListener { docSnapshot, _ in
                let data = docSnapshot?.data() ?? [:]
                pendingRequestCount = (data["friendRequests"] as? [String])?.count ?? 0
            }
    }
}
