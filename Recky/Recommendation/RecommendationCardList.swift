//
//  RecommendationCardList.swift
//  Recky
//
//  Created by Paul Winters on 6/28/25.
//


import SwiftUI
import FirebaseAuth

struct RecommendationCardList: View {
    let recommendations: [Recommendation]
    let maxCount: Int?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(recommendations.prefix(maxCount ?? recommendations.count)) { rec in
                let isSent = rec.fromUID == Auth.auth().currentUser?.uid

                NavigationLink(
                    destination: isSent
                        ? AnyView(SentRecommendationDetailView(recommendation: rec))
                        : AnyView(RecommendationDetailView(recommendation: rec))
                ) {
                    RecommendationRowView(recommendation: rec, isSent: isSent)
                }
            }
        }
    }
}
