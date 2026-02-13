import SwiftUI
import SwiftData

@main
struct ChanneledApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Household.self,
            User.self,
            Show.self,
            ScheduledSlot.self,
            ViewingWindow.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
