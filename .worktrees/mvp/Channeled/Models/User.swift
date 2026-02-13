// Channeled/Models/User.swift
import Foundation
import SwiftData

@Model
final class User: Identifiable {
    var id: String
    var name: String
    var householdId: String
    @Relationship(deleteRule: .nullify) var watchlist: [Show]
    @Relationship(deleteRule: .cascade) var viewingWindows: [ViewingWindow]

    init(id: String = UUID().uuidString, name: String, householdId: String) {
        self.id = id
        self.name = name
        self.householdId = householdId
        self.watchlist = []
        self.viewingWindows = []
    }
}
