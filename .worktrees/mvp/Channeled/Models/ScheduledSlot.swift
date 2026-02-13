// Channeled/Models/ScheduledSlot.swift
import Foundation
import SwiftData

@Model
final class ScheduledSlot: Identifiable {
    var id: String
    var householdId: String
    var startTime: Date
    var duration: Int // minutes
    var type: SlotType
    var showId: String?
    var episodeCount: Int
    var familyFriendly: Bool
    var partnerMustLike: Bool

    @Relationship(deleteRule: .nullify) var household: Household?

    init(id: String = UUID().uuidString, householdId: String, startTime: Date,
         duration: Int, type: SlotType, showId: String? = nil,
         episodeCount: Int = 1, familyFriendly: Bool = false, partnerMustLike: Bool = false) {
        self.id = id
        self.householdId = householdId
        self.startTime = startTime
        self.duration = duration
        self.type = type
        self.showId = showId
        self.episodeCount = episodeCount
        self.familyFriendly = familyFriendly
        self.partnerMustLike = partnerMustLike
    }
}

enum SlotType: String, Codable {
    case booked, recurring, generated, placeholder
}
