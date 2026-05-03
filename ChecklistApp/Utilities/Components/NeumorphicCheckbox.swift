import SwiftUI

struct NeumorphicCheckbox: View {
    let isChecked: Bool
    let action: () -> Void
    var size: CGFloat = 28

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isChecked ? AnyShapeStyle(Color.orangeGradient) : AnyShapeStyle(Color.neumorphicSurface))
                    .frame(width: size, height: size)
                    .neumorphicShadow(isPressed: isChecked, subtle: true)

                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.5, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isChecked)
    }
}

// MARK: - Circle Checkbox (Alternative Style)

struct NeumorphicCircleCheckbox: View {
    let isChecked: Bool
    let action: () -> Void
    var size: CGFloat = 24

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(
                        isChecked ? Color.accentOrangeStart : Color.neumorphicTextTertiary,
                        lineWidth: 2
                    )
                    .frame(width: size, height: size)

                if isChecked {
                    Circle()
                        .fill(Color.orangeGradient)
                        .frame(width: size - 8, height: size - 8)
                        .transition(.scale)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isChecked)
    }
}

#if false
#Preview {
    ZStack {
        Color.neumorphicBackground.ignoresSafeArea()

        VStack(spacing: 30) {
            HStack(spacing: 30) {
                NeumorphicCheckbox(isChecked: false, action: {})
                NeumorphicCheckbox(isChecked: true, action: {})
            }

            HStack(spacing: 30) {
                NeumorphicCircleCheckbox(isChecked: false, action: {})
                NeumorphicCircleCheckbox(isChecked: true, action: {})
            }
        }
    }
}
#endif
