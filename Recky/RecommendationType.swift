//
//  RecommendationType.swift
//  Recky
//
//  Created by Paul Winters on 6/22/25.
//


enum RecommendationType: String, CaseIterable {
    case movie, book, album, tv, game

    var emoji: String {
        EmojiUtils.forType(rawValue)
    }

    var displayName: String {
        "\(emoji) \(rawValue.capitalized)"
    }
}
