import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showMainContent = false
    let onFinished: () -> Void

    var body: some View {
        ZStack {
            // Background
            Color.white
                .ignoresSafeArea()

            VStack(spacing: NeumorphicSpacing.lg) {
                // Logo image
                Image("splush")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                onFinished()
            }
        }
    }
}

#if false
#Preview {
    SplashView {
        print("Splash finished")
    }
}
#endif
