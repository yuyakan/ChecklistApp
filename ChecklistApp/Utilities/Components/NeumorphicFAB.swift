import SwiftUI

struct NeumorphicFAB: View {
    let action: () -> Void
    var icon: String = "plus"
    var size: CGFloat = 60

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(Color.orangeGradient)
                )
                .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .shadow(
            color: Color.accentOrangeEnd.opacity(0.5),
            radius: 12,
            x: 0,
            y: 6
        )
        .shadow(
            color: Color.neumorphicDarkShadow,
            radius: 8,
            x: 4,
            y: 4
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

#if false
#Preview {
    ZStack {
        Color.neumorphicBackground.ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                NeumorphicFAB(action: {})
                    .padding()
            }
        }
    }
}
#endif
