//
//  RecommendationDetailView.swift
//  Recky
//
//  Created by Paul Winters on 6/21/25.
//


import SwiftUI

struct RecommendationDetailView: View {
    var recommendation: Recommendation

    var body: some View {
        VStack(spacing: 20) {
            Text(recommendation.title)
                .font(.largeTitle)
                .bold()

            Text("Type: \(recommendation.type)")
                .font(.title3)
                .foregroundColor(.secondary)

            if let notes = recommendation.notes, !notes.isEmpty {
                Text("“\(notes)”")
                    .italic()
                    .padding()
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
