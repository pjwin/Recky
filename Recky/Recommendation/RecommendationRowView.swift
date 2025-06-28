//
//  RecommendationRowView.swift
//  Recky
//
//  Created by Paul Winters on 6/28/25.
//


import SwiftUI

struct RecommendationRowView: View {
    let recommendation: Recommendation
    let isSent: Bool

    var body: some View {
        let hasVoted = recommendation.vote != nil
        let typeEmoji = EmojiUtils.forType(recommendation.type)
        let voteIconName: String? = {
            switch recommendation.vote {
            case true: return "hand.thumbsup.fill"
            case false: return "hand.thumbsdown.fill"
            default: return nil
            }
        }()

        HStack(alignment: .top, spacing: 12) {
            Group {
                if let iconName = voteIconName {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(recommendation.vote == true ? .blue : .red)
                } else {
                    Color.clear.frame(width: 22, height: 22)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text("\(typeEmoji) \(recommendation.title)")
                        .font(.body)
                        .lineLimit(1)

                    Spacer()

                    if !hasVoted && !isSent {
                        Text("NEW")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(4)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }

                Text(
                    isSent
                    ? "to @\(recommendation.toUsername ?? "unknown")"
                    : "from @\(recommendation.fromUsername ?? "unknown")"
                )
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
            !hasVoted
                ? RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                : nil
        )
    }
}
