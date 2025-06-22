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
    var title: String
    var type: String
    var notes: String?
    var vote: Bool?

    // Not in Firestore, populated manually
    var fromUsername: String = "unknown"
}
