import FirebaseFirestore
import Foundation

struct Recommendation: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var fromUID: String
    var toUID: String
    var title: String
    var tags: [String]
    var notes: String?
    var timestamp: Date
    var vote: Bool?
    var voteNote: String? = nil
    var fromUsername: String?
    var toUsername: String?
    var hasBeenViewedByRecipient: Bool? = false

    enum CodingKeys: String, CodingKey {
        case id
        case fromUID
        case toUID
        case title
        case tags
        case type // for backwards compatibility
        case notes
        case timestamp
        case vote
        case voteNote
        case fromUsername
        case toUsername
        case hasBeenViewedByRecipient
    }

    init(
        id: String? = nil,
        fromUID: String,
        toUID: String,
        title: String,
        tags: [String],
        notes: String? = nil,
        timestamp: Date,
        vote: Bool? = nil,
        voteNote: String? = nil,
        fromUsername: String? = nil,
        toUsername: String? = nil,
        hasBeenViewedByRecipient: Bool? = false
    ) {
        self.id = id
        self.fromUID = fromUID
        self.toUID = toUID
        self.title = title
        self.tags = tags
        self.notes = notes
        self.timestamp = timestamp
        self.vote = vote
        self.voteNote = voteNote
        self.fromUsername = fromUsername
        self.toUsername = toUsername
        self.hasBeenViewedByRecipient = hasBeenViewedByRecipient
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        fromUID = try container.decode(String.self, forKey: .fromUID)
        toUID = try container.decode(String.self, forKey: .toUID)
        title = try container.decode(String.self, forKey: .title)
        if let tagList = try container.decodeIfPresent([String].self, forKey: .tags) {
            tags = tagList
        } else if let singleType = try container.decodeIfPresent(String.self, forKey: .type) {
            tags = [singleType]
        } else {
            tags = []
        }
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        vote = try container.decodeIfPresent(Bool.self, forKey: .vote)
        voteNote = try container.decodeIfPresent(String.self, forKey: .voteNote)
        fromUsername = try container.decodeIfPresent(String.self, forKey: .fromUsername)
        toUsername = try container.decodeIfPresent(String.self, forKey: .toUsername)
        hasBeenViewedByRecipient = try container.decodeIfPresent(Bool.self, forKey: .hasBeenViewedByRecipient)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(fromUID, forKey: .fromUID)
        try container.encode(toUID, forKey: .toUID)
        try container.encode(title, forKey: .title)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(vote, forKey: .vote)
        try container.encodeIfPresent(voteNote, forKey: .voteNote)
        try container.encodeIfPresent(fromUsername, forKey: .fromUsername)
        try container.encodeIfPresent(toUsername, forKey: .toUsername)
        try container.encodeIfPresent(
            hasBeenViewedByRecipient,
            forKey: .hasBeenViewedByRecipient
        )
    }
}
