// Channeled/Models/Household.swift
import Foundation
import SwiftData

@Model
final class Household: Identifiable {
    var id: String
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var members: [User]
    @Relationship(deleteRule: .cascade) var scheduledSlots: [ScheduledSlot]

    init(id: String = UUID().uuidString, name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.members = []
        self.scheduledSlots = []
    }
}
