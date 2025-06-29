//
//  RecommendationRowView.swift
//  Recky
//
//  Created by Paul Winters on 6/28/25.
//

import FirebaseAuth
import SwiftUI

struct RecommendationCardView: View {
    let recommendation: Recommendation
    let isSent: Bool

    var body: some View {
        let currentUserUID = Auth.auth().currentUser?.uid
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
                        .foregroundColor(
                            recommendation.vote == true ? .blue : .red
                        )
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

                    if let currentUserUID = currentUserUID,
                        recommendation.toUID == currentUserUID,
                        !(recommendation.hasBeenViewedByRecipient ?? false)
                    {
                        Text("NEW")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(10)
                            .transition(.opacity)
                    }
                }

                HStack {
                    Text(
                        isSent
                            ? "to @\(recommendation.toUsername ?? "unknown")"
                            : "from @\(recommendation.fromUsername ?? "unknown")"
                    )

                    Spacer()

                    Text(timeAgoString(from: recommendation.timestamp))
                }
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
        .animation(.easeOut(duration: 0.3), value: recommendation.hasBeenViewedByRecipient)
    }

    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
