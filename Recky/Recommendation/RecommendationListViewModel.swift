//
//  RecommendationListViewModel.swift
//  Recky
//
//  Created by Paul Winters on 6/28/25.
//


import Foundation
import FirebaseFirestore
import FirebaseAuth

class RecommendationListViewModel: ObservableObject {
    @Published var allRecommendations: [Recommendation] = []
    @Published var filteredRecommendations: [Recommendation] = []
    @Published var showReceived = true
    @Published var showSent = true
    @Published var selectedType: String? = nil
    @Published var selectedUser: String? = nil
    @Published var loading = false
    @Published var titleQuery: String = ""


    private var myUID: String? {
        Auth.auth().currentUser?.uid
    }

    func fetchAllRecommendations() {
        guard let uid = myUID else { return }
        loading = true

        Firestore.firestore().collection("recommendations")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                self.loading = false
                guard error == nil else { return }

                let docs = snapshot?.documents ?? []
                var results: [Recommendation] = []
                let group = DispatchGroup()

                for doc in docs {
                    if var rec = try? doc.data(as: Recommendation.self) {
                        rec.id = doc.documentID
                        rec.hasBeenViewedByRecipient = doc.get("hasBeenViewedByRecipient") as? Bool ?? false
                        group.enter()

                        let userID = rec.fromUID == uid ? rec.toUID : rec.fromUID
                        let usernameKey = rec.fromUID == uid ? "toUsername" : "fromUsername"

                        Firestore.firestore().collection("users").document(userID).getDocument { userDoc, _ in
                            let username = userDoc?.get("username") as? String ?? "unknown"
                            if usernameKey == "fromUsername" {
                                rec.fromUsername = username
                            } else {
                                rec.toUsername = username
                            }
                            results.append(rec)
                            group.leave()
                        }
                    }
                }

                group.notify(queue: .main) {
                    self.allRecommendations = results
                    self.applySearch()
                }
            }
    }

    func applySearch() {
        guard let uid = myUID else { return }

        filteredRecommendations = allRecommendations.filter { rec in
            let isSent = rec.fromUID == uid
            let isReceived = rec.toUID == uid

            let directionAllowed = (isSent && showSent) || (isReceived && showReceived)
            let matchesType = selectedType == nil || rec.type.lowercased() == selectedType?.lowercased()
            let matchesUser = selectedUser == nil ||
                (isSent && rec.toUsername?.lowercased().contains(selectedUser!.lowercased()) == true) ||
                (isReceived && rec.fromUsername?.lowercased().contains(selectedUser!.lowercased()) == true)
            let matchesTitle = titleQuery.isEmpty || rec.title.lowercased().contains(titleQuery.lowercased())

            return directionAllowed && matchesType && matchesUser && matchesTitle
        }
    }


    func resetSearch() {
        showReceived = true
        showSent = true
        selectedType = nil
        selectedUser = nil
        titleQuery = ""
        applySearch()
    }
}
