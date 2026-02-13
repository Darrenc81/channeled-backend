// Channeled/Models/ViewingWindow.swift
import Foundation
import SwiftData

@Model
final class ViewingWindow: Identifiable {
    var id: String
    var userId: String
    var dayOfWeek: DayOfWeek
    var startTime: String // HH:mm format
    var endTime: String
    var type: WindowType
    var label: String

    @Relationship(deleteRule: .nullify) var user: User?

    init(id: String = UUID().uuidString, userId: String, dayOfWeek: DayOfWeek,
         startTime: String, endTime: String, type: WindowType, label: String) {
        self.id = id
        self.userId = userId
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.type = type
        self.label = label
    }
}

enum DayOfWeek: Int, Codable, CaseIterable {
    case sunday = 0, monday = 1, tuesday = 2, wednesday = 3, thursday = 4, friday = 5, saturday = 6
}

enum WindowType: String, Codable {
    case shared, solo
}
