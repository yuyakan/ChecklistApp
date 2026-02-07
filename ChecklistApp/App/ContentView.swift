import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var navigationState: NavigationState
    @State private var showSplash = true
    @State private var showingSharedChecklists = false

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
        .sheet(isPresented: $showingSharedChecklists) {
            NavigationStack {
                SharedChecklistsView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CloudKitShareAccepted"))) { _ in
            // 共有を受け入れた後、共有リスト画面を表示
            showingSharedChecklists = true
        }
        .onChange(of: navigationState.showingSharedChecklists) { _, newValue in
            showingSharedChecklists = newValue
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NavigationState())
        .modelContainer(for: Checklist.self, inMemory: true)
}
