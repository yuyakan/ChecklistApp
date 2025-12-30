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
        .modelContainer(for: Checklist.self, inMemory: true)
}
