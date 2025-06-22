//
//  HomeView.swift
//  Recky
//
//  Created by Paul Winters on 6/17/25.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: SessionManager
    @State private var recommendations: [Recommendation] = []
    @State private var showSendView = false
    @State private var showProfile = false
    @State private var pendingRequestCount: Int = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerBar

                Divider()

                latestRecommendationsSection

                Spacer()

                recommendButton
            }
            .padding()
            .sheet(isPresented: $showSendView) {
                SendRecommendationView()
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .onAppear {
                loadRecommendations()
                startListeningForFriendRequests()
            }
        }
    }

    private var headerBar: some View {
        ZStack {
            HStack {
                // Logo on the left
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

            // Centered welcome message
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

    private var latestRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader

            if recommendations.isEmpty {
                emptyStateText
            } else {
                recommendationList
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sectionHeader: some View {
        Text("📢  Latest Recommendations")
            .font(.headline)
    }

    private var emptyStateText: some View {
        Text("No recent recommendations.")
            .foregroundColor(.gray)
            .padding(.top, 8)
    }

    private var recommendationList: some View {
        ForEach(Array(recommendations.prefix(5))) { rec in
            NavigationLink(destination: RecommendationDetailView(recommendation: rec)) {
                recommendationRow(for: rec)
            }
        }
    }

    private func recommendationRow(for rec: Recommendation) -> some View {
        let hasVoted = rec.vote != nil
        let typeEmoji = emojiForType(rec.type)

        let voteIconName: String? = {
            switch rec.vote {
            case true: return "hand.thumbsup.fill"
            case false: return "hand.thumbsdown.fill"
            default: return nil
            }
        }()

        return HStack(alignment: .top, spacing: 12) {
            // Vote icon if present, or placeholder
            Group {
                if let iconName = voteIconName {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(rec.vote == true ? .blue : .red)
                } else {
                    // Reserve the same space as the icon
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

    private func loadRecommendations() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()

        db.collection("recommendations")
            .whereField("toUID", isEqualTo: myUID)
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to fetch recommendations: \(error)")
                    return
                }

                let docs = snapshot?.documents ?? []
                var results: [Recommendation] = []
                let group = DispatchGroup()

                for doc in docs {
                    if var rec = try? doc.data(as: Recommendation.self) {
                        rec.id = doc.documentID
                        group.enter()

                        // Fetch the username of the sender
                        db.collection("users").document(rec.fromUID).getDocument { userDoc, _ in
                            let username = userDoc?.get("username") as? String ?? "unknown"
                            rec.fromUsername = username
                            results.append(rec)
                            group.leave()
                        }
                    }
                }

                group.notify(queue: .main) {
                    self.recommendations = results
                }
            }
    }

    private func voteEmoji(for vote: Bool?) -> some View {
        let iconName: String
        let color: Color

        switch vote {
        case true:
            iconName = "hand.thumbsup.fill"
            color = .blue
        case false:
            iconName = "hand.thumbsdown.fill"
            color = .red
        default:
            iconName = "star"
            color = .gray
        }

        return Image(systemName: iconName)
            .foregroundColor(color)
            .font(.title3)
    }
    
    private func formattedTimeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    func startListeningForFriendRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").document(uid)
            .addSnapshotListener { docSnapshot, error in
                guard let doc = docSnapshot, let data = doc.data() else { return }
                let requests = data["friendRequests"] as? [String] ?? []
                pendingRequestCount = requests.count
            }
    }
    
    private func emojiForType(_ type: String) -> String {
        switch type.lowercased() {
        case "movie": return "🎬"
        case "tv": return "📺"
        case "book": return "📚"
        case "album": return "🎧"
        case "game": return "🎮"
        default: return "❓"
        }
    }
}
