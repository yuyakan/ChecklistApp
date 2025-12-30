import SwiftUI
import SwiftData

@main
struct ChecklistApp: App {
    var sharedModelContainer: ModelContainer = AppGroupContainer.modelContainer

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
