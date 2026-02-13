// Channeled/Models/TMDBShow.swift
import Foundation

/// Show type enum for TMDB content
enum TMDBShowType: String, Codable {
    case movie
        case series
}

/// A TMDB show model representing a movie or TV series from The Movie Database API
struct TMDBShow: Codable, Identifiable, Hashable {
    let id: Int
    let type: TMDBShowType
    let title: String
    let overview: String
    let artworkURL: String?
    let backdropURL: String?
    let genres: [String]
    let runtime: Int
    let contentRating: String?
    let releaseDate: String
    let rating: Double

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case overview
        case artworkURL = "artworkUrl"
        case backdropURL = "backdropUrl"
        case genres
        case runtime
        case contentRating = "contentRating"
        case releaseDate = "releaseDate"
        case rating
    }

    /// Formatted release year (e.g., "2024")
    var releaseYear: String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: releaseDate) else { return nil }
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        return yearFormatter.string(from: date)
    }

    /// Formatted runtime as hours and minutes (e.g., "2h 15m")
    var formattedRuntime: String? {
        guard runtime > 0 else { return nil }
        let hours = runtime / 60
        let minutes = runtime % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Rating formatted as a string with star emoji (e.g., "8.5")
    var formattedRating: String {
        String(format: "%.1f", rating)
    }
}

/// TMDB search response from the backend API
struct TMDBSearchResponse: Codable {
    let results: [TMDBShow]
}

/// TMDB show detail response from the backend API
struct TMDBShowDetailResponse: Codable {
    let result: TMDBShow
}

/// Trending shows response
struct TMDBTrendingResponse: Codable {
    let results: [TMDBShow]
}
