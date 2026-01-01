import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            HomeView()
                .applyAppTheme()
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NavigationState())
        .modelContainer(for: Checklist.self, inMemory: true)
}
