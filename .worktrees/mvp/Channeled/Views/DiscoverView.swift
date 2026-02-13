// Channeled/Views/DiscoverView.swift
import SwiftUI

struct DiscoverView: View {
    var body: some View {
        NavigationStack {
            Text("TMDB Search - Coming Soon")
                .navigationTitle("Discover")
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
    DiscoverView()
}
