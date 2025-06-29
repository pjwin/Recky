//
//  Recommendation.swift
//  Recky
//
//  Created by Paul Winters on 6/20/25.
//

import FirebaseFirestore
import Foundation

struct Recommendation: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var fromUID: String
    var toUID: String
    var title: String
    var type: String
    var notes: String?
    var timestamp: Date
    var vote: Bool?
    var voteNote: String? = nil
    var fromUsername: String?
    var toUsername: String?
    var hasBeenViewedByRecipient: Bool? = false
}
