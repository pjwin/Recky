//
//  EmojiUtils.swift
//  Recky
//
//  Created by Paul Winters on 6/22/25.
//


import Foundation

enum EmojiUtils {
    static func forType(_ type: String) -> String {
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
