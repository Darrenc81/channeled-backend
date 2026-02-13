// Channeled/Models/Show.swift
import Foundation
import SwiftData

@Model
final class Show: Identifiable {
    var id: String
    var tmdbId: Int
    var type: ShowType
    var title: String
    var overview: String?
    var artworkURL: String?
    var genres: [String]
    var runtime: Int
    var contentRating: String?
    var isBingeable: Bool
    var partnerApproved: Bool
    var moodTags: [String]

    init(id: String = UUID().uuidString, tmdbId: Int, type: ShowType, title: String,
         overview: String? = nil, artworkURL: String? = nil, genres: [String] = [],
         runtime: Int = 0, contentRating: String? = nil, isBingeable: Bool = false,
         partnerApproved: Bool = false, moodTags: [String] = []) {
        self.id = id
        self.tmdbId = tmdbId
        self.type = type
        self.title = title
        self.overview = overview
        self.artworkURL = artworkURL
        self.genres = genres
        self.runtime = runtime
        self.contentRating = contentRating
        self.isBingeable = isBingeable
        self.partnerApproved = partnerApproved
        self.moodTags = moodTags
    }
}

enum ShowType: String, Codable {
    case movie, series
}
