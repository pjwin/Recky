import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct HomeView: View {
    @AppStorage("hasPulledToRefresh") private var hasPulledToRefresh = false
    @EnvironmentObject var session: SessionManager

    @State private var recs: [Recommendation] = []
    @State private var sentRecs: [Recommendation] = []
    @State private var showAllRecs = false
    @State private var showAllSentRecs = false
    @State private var isRecsExpanded = true
    @State private var isSentExpanded = true
    @State private var showSendView = false
    @State private var showProfile = false
    @State private var pendingFriendRequestCount: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                headerBar

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        recommendationsSection
                        sentRecommendationsSection
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    loadAllRecommendations()
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
            .navigationDestination(isPresented: $showAllRecs) {
                RecommendationsView()
            }
            .navigationDestination(isPresented: $showAllSentRecs) {
                SentRecommendationsView()
            }
            .onAppear {
                loadAllRecommendations()
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

                    if pendingFriendRequestCount > 0 {
                        Text("\(pendingFriendRequestCount)")
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

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: {
                    isRecsExpanded.toggle()
                }) {
                    HStack {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isRecsExpanded ? 90 : 0))
                            .animation(
                                .easeInOut(duration: 0.2),
                                value: isRecsExpanded
                            )
                        Text("Latest Recommendations")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }

                Spacer()

                Button("See All >") {
                    showAllRecs = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }

            if isRecsExpanded {
                if recs.isEmpty {
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

                        RecommendationCardList(
                            recommendations: recs,
                            maxCount: 5
                        )
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
                            .animation(
                                .easeInOut(duration: 0.2),
                                value: isSentExpanded
                            )
                        Text("Sent Recommendations")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }

                Spacer()

                Button("See All >") {
                    showAllSentRecs = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }

            if isSentExpanded {
                if sentRecs.isEmpty {
                    Text("You haven't sent any yet.")
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                } else {
                    VStack(spacing: 12) {
                        RecommendationCardList(
                            recommendations: sentRecs,
                            maxCount: 5
                        )
                    }
                    .padding(.top)
                }
            }
        }
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

    private func loadAllRecommendations() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }

        fetchRecommendations(
            matchingField: "toUID",
            equalTo: myUID,
            assignUsernameTo: \.fromUsername,
            assignTo: { self.recs = $0 }
        )

        fetchRecommendations(
            matchingField: "fromUID",
            equalTo: myUID,
            assignUsernameTo: \.toUsername,
            assignTo: { self.sentRecs = $0 }
        )
    }

    private func fetchRecommendations(
        matchingField field: String,
        equalTo uid: String,
        assignUsernameTo assignKeyPath: WritableKeyPath<
            Recommendation, String?
        >,
        assignTo output: @escaping ([Recommendation]) -> Void
    ) {
        let db = Firestore.firestore()

        db.collection("recommendations")
            .whereField(field, isEqualTo: uid)
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

                        // Decide which UID to fetch username for
                        let lookupUID =
                            field == "toUID" ? rec.fromUID : rec.toUID

                        db.collection("users").document(lookupUID).getDocument {
                            userDoc,
                            _ in
                            let username =
                                userDoc?.get("username") as? String ?? "unknown"
                            rec[keyPath: assignKeyPath] = username
                            results[index] = rec
                            group.leave()
                        }
                    }
                }

                group.notify(queue: .main) {
                    let sorted = (0..<docs.count).compactMap { results[$0] }
                    output(sorted)
                }
            }
    }

    // MARK: Friend Request Listener

    func startListeningForFriendRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").document(uid)
            .addSnapshotListener { docSnapshot, _ in
                let data = docSnapshot?.data() ?? [:]
                pendingFriendRequestCount =
                    (data["friendRequests"] as? [String])?.count ?? 0
            }
    }
}
