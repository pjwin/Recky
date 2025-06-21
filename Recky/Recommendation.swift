//
//  Recommendation.swift
//  Recky
//
//  Created by Paul Winters on 6/20/25.
//


import Foundation
import FirebaseFirestore

struct Recommendation: Identifiable, Codable {
    @DocumentID var id: String?
    var fromUID: String
    var toUID: String
    var type: String
    var title: String
    var notes: String?
    var timestamp: Date
    var vote: Bool? // true = good, false = bad, nil = no vote
}
