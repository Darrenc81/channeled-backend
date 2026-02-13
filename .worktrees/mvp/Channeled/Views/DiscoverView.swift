// Channeled/Views/DiscoverView.swift
import SwiftUI

struct DiscoverView: View {
    @State private var searchText = ""
    @State private var searchResults: [TMDBShow] = []
    @State private var isSearching = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                    .padding()

                if isSearching {
                    ProgressView()
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding()
                } else if !searchText.isEmpty && searchResults.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else if searchResults.isEmpty {
                    ContentUnavailableView("Search for shows and movies",
                                       systemImage: "magnifyingglass")
                } else {
                    searchResultsGrid
                }

                Spacer()
            }
            .navigationTitle("Discover")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "gear")
                    }
                }
            }
            .onChange(of: searchText) { _, newValue in
                Task {
                    await performSearch(query: newValue)
                }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search shows, movies...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.quaternary, lineWidth: 1)
        )
    }

    private var searchResultsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120, maximum: 180), spacing: 16)], spacing: 16) {
                ForEach(searchResults) { show in
                    showPoster(for: show)
                }
            }
            .padding()
        }
    }

    private func showPoster(for show: TMDBShow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            AsyncImage(url: show.artworkURL.map { URL(string: $0) } ?? nil) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                        .frame(width: 120, height: 180)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                        .frame(width: 120, height: 180)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.tertiary)
                        }
                @unknown default:
                    EmptyView()
                }
            }

            Text(show.title)
                .font(.caption)
                .lineLimit(2)
                .frame(width: 120)
        }
    }

    private func performSearch(query: String) async {
        guard query.count >= 2 else {
            searchResults = []
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            let results = try await TMDBService.shared.search(query: query)
            searchResults = results
        } catch {
            errorMessage = "Search failed. Please try again."
            searchResults = []
        }

        isSearching = false
    }
}

#Preview {
    DiscoverView()
}
