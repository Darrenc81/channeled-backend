// Channeled/Services/TMDBService.swift
import Foundation

/// Service for interacting with TMDB (The Movie Database) API via the backend
actor TMDBService {
    static let shared = TMDBService()

    private let baseURL: String
    private let session: URLSession

    private init() {
        // Use environment variable or Railway backend for development
        if let apiURL = ProcessInfo.processInfo.environment["CHANNELED_API_URL"] {
            self.baseURL = apiURL
        } else {
            self.baseURL = "https://channeled-backend-production.up.railway.app"
        }

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    private func makeURL(endpoint: String, queryItems: [URLQueryItem] = []) -> URL? {
        var components = URLComponents(string: "\(baseURL)\(endpoint)")
        components?.queryItems = queryItems
        return components?.url
    }

    /// Search for movies and TV shows
    /// - Parameter query: The search query string
    /// - Returns: An array of TMDBShow results
    func search(query: String) async throws -> [TMDBShow] {
        guard let url = makeURL(endpoint: "/api/search/tmdb", queryItems: [URLQueryItem(name: "q", value: query)]) else {
            throw TMDBError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw TMDBError.httpError(statusCode: httpResponse.statusCode)
        }

        let searchResponse = try JSONDecoder().decode(TMDBSearchResponse.self, from: data)
        return searchResponse.results
    }

    /// Get trending shows
    /// - Parameter timeWindow: The time window ("day" or "week")
    /// - Returns: An array of trending TMDBShow results
    func trending(timeWindow: TrendingTimeWindow = .week) async throws -> [TMDBShow] {
        guard let url = makeURL(endpoint: "/api/search/tmdb", queryItems: [URLQueryItem(name: "trending", value: timeWindow.rawValue)]) else {
            throw TMDBError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw TMDBError.httpError(statusCode: httpResponse.statusCode)
        }

        let trendingResponse = try JSONDecoder().decode(TMDBTrendingResponse.self, from: data)
        return trendingResponse.results
    }

    /// Get detailed information about a specific show
    /// - Parameters:
    ///   - id: The TMDB ID of the show
    ///   - type: The type of show (movie or series)
    /// - Returns: A TMDBShow with full details
    func getDetails(id: Int, type: TMDBShowType) async throws -> TMDBShow {
        guard let url = makeURL(
            endpoint: "/api/search/tmdb/\(id)",
            queryItems: [URLQueryItem(name: "type", value: type.rawValue)]
        ) else {
            throw TMDBError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw TMDBError.httpError(statusCode: httpResponse.statusCode)
        }

        let detailResponse = try JSONDecoder().decode(TMDBShowDetailResponse.self, from: data)
        return detailResponse.result
    }

    enum TrendingTimeWindow: String {
        case day
        case week
    }
}

// MARK: - Errors

enum TMDBError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Loading State

enum TMDBLoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)
}
