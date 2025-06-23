//
//  FriendStats.swift
//  Recky
//
//  Created by Paul Winters on 6/22/25.
//


struct FriendStats {
    let sentThumbsUp: Int
    let sentThumbsDown: Int
    let receivedThumbsUp: Int
    let receivedThumbsDown: Int

    var sentCount: Int { sentThumbsUp + sentThumbsDown }
    var receivedCount: Int { receivedThumbsUp + receivedThumbsDown }

    var sentPercent: Int {
        sentCount == 0 ? 0 : (sentThumbsUp * 100 / sentCount)
    }

    var receivedPercent: Int {
        receivedCount == 0 ? 0 : (receivedThumbsUp * 100 / receivedCount)
    }

    var sentText: String {
        "\(sentThumbsUp)/\(sentCount) (\(sentPercent)%)"
    }

    var receivedText: String {
        "\(receivedThumbsUp)/\(receivedCount) (\(receivedPercent)%)"
    }
}