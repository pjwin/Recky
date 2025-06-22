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

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerBar

                welcomeSection

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
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Image("AppLogo")
                .resizable()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Spacer()
            Button(action: {
                showProfile = true
            }) {
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width: 28, height: 28)
            }
        }
    }

    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back,")
                .font(.headline)
            if let email = session.user?.email {
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        HStack {
            Text(voteEmoji(for: rec.vote))

            VStack(alignment: .leading) {
                Text("“\(rec.title)”")
                    .lineLimit(1)
                Text("from @\(rec.fromUsername)")
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

    private func voteEmoji(for vote: Bool?) -> String {
        switch vote {
        case true: return "👍"
        case false: return "👎"
        default: return "⭐️"
        }
    }
}
