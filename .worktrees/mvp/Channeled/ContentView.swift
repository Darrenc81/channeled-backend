import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }

            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }

            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "list.bullet")
                }
        }
    }
}

#Preview {
    ContentView()
}
