// Channeled/Views/WatchlistView.swift
import SwiftUI

struct WatchlistView: View {
    var body: some View {
        NavigationStack {
            Text("My Watchlist - Coming Soon")
                .navigationTitle("Watchlist")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {}) {
                            Image(systemName: "gear")
                        }
                    }
                }
        }
    }
}

#Preview {
    WatchlistView()
}
