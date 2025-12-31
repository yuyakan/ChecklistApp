import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        HomeView()
            .applyAppTheme()
    }
}

#Preview {
    ContentView()
        .environmentObject(NavigationState())
        .modelContainer(for: Checklist.self, inMemory: true)
}
