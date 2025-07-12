enum RecommendationType: String, CaseIterable {
    case movie, book, album, tv, game

    var emoji: String {
        EmojiUtils.forType(rawValue)
    }

    var displayName: String {
        "\(emoji) \(rawValue.capitalized)"
    }
}
