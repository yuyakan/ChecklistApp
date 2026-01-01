import SwiftUI

// MARK: - Standard Neumorphic Button

struct NeumorphicButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    @State private var isPressed = false

    init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }) {
            label()
                .padding(NeumorphicSpacing.md)
                .background(Color.neumorphicSurface)
                .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.md))
        }
        .buttonStyle(.plain)
        .neumorphicShadow(isPressed: isPressed)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - Accent Neumorphic Button

struct NeumorphicAccentButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    var isDisabled: Bool = false

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: NeumorphicSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.vertical, NeumorphicSpacing.sm)
            .padding(.horizontal, NeumorphicSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: NeumorphicRadius.md)
                    .fill(isDisabled ? AnyShapeStyle(Color.neumorphicTextTertiary) : AnyShapeStyle(Color.orangeGradient))
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .shadow(
            color: isDisabled ? Color.clear : Color.accentOrangeEnd.opacity(0.4),
            radius: 8,
            x: 0,
            y: 4
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isDisabled {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
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

// MARK: - Unified Button

enum NeumorphicButtonStyle {
    case standard
    case accent
    case secondary
}

extension NeumorphicButton where Label == Text {
    init(title: String, style: NeumorphicButtonStyle = .standard, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.init(action: action) {
            Text(title)
        }
    }
}

struct NeumorphicButton_Unified: View {
    let title: String
    let style: NeumorphicButtonStyle
    let isEnabled: Bool
    let action: () -> Void
    var icon: String? = nil

    @State private var isPressed = false

    init(title: String, style: NeumorphicButtonStyle = .accent, isEnabled: Bool = true, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.isEnabled = isEnabled
        self.icon = icon
        self.action = action
    }

    var body: some View {
        switch style {
        case .standard:
            standardButton
        case .accent:
            accentButton
        case .secondary:
            secondaryButton
        }
    }

    private var standardButton: some View {
        Button(action: action) {
            HStack(spacing: NeumorphicSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.medium)
            }
            .padding(NeumorphicSpacing.md)
            .background(Color.neumorphicSurface)
            .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.md))
        }
        .buttonStyle(.plain)
        .neumorphicShadow(isPressed: isPressed)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if isEnabled {
                        withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                }
        )
    }

    private var accentButton: some View {
        Button(action: action) {
            HStack(spacing: NeumorphicSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.vertical, NeumorphicSpacing.sm)
            .padding(.horizontal, NeumorphicSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: NeumorphicRadius.md)
                    .fill(isEnabled ? AnyShapeStyle(Color.orangeGradient) : AnyShapeStyle(Color.neumorphicTextTertiary))
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .shadow(
            color: isEnabled ? Color.accentOrangeEnd.opacity(0.4) : Color.clear,
            radius: 8,
            x: 0,
            y: 4
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if isEnabled {
                        withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                }
        )
    }

    private var secondaryButton: some View {
        Button(action: action) {
            HStack(spacing: NeumorphicSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Color.accentOrangeStart)
            .padding(.vertical, NeumorphicSpacing.sm)
            .padding(.horizontal, NeumorphicSpacing.md)
            .background(Color.neumorphicSurface)
            .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: NeumorphicRadius.md)
                    .stroke(Color.accentOrangeStart.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
        .neumorphicShadow(isPressed: isPressed, subtle: true)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if isEnabled {
                        withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                }
        )
    }
}

// Typealias for easier usage in views
typealias NeumorphicButton_Styled = NeumorphicButton_Unified

// MARK: - Secondary Button

struct NeumorphicSecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: NeumorphicSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Color.accentOrangeStart)
            .padding(.vertical, NeumorphicSpacing.sm)
            .padding(.horizontal, NeumorphicSpacing.md)
            .background(Color.neumorphicSurface)
            .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: NeumorphicRadius.md)
                    .stroke(Color.accentOrangeStart.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .neumorphicShadow(isPressed: isPressed, subtle: true)
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

#Preview {
    ZStack {
        Color.neumorphicBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            NeumorphicButton(action: {}) {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Standard Button")
                }
            }

            NeumorphicAccentButton(title: "Accent Button", icon: "sparkles", action: {})

            NeumorphicAccentButton(title: "Disabled", action: {}, isDisabled: true)

            NeumorphicSecondaryButton(title: "Secondary", icon: "arrow.right", action: {})
        }
        .padding()
    }
}
