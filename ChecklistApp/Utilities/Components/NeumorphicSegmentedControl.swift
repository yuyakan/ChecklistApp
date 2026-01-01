import SwiftUI

struct NeumorphicSegmentedControl<T: Hashable>: View {
    let options: [T]
    @Binding var selection: T
    let label: (T) -> String
    let icon: (T) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                NeumorphicSegmentButton(
                    isSelected: selection == option,
                    label: label(option),
                    icon: icon(option)
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = option
                    }
                }
            }
        }
        .padding(NeumorphicSpacing.xxs)
        .background(Color.neumorphicBackground)
        .clipShape(RoundedRectangle(cornerRadius: NeumorphicRadius.md))
        .shadow(
            color: Color.neumorphicDarkShadow,
            radius: 4,
            x: 2,
            y: 2
        )
        .shadow(
            color: Color.neumorphicLightShadow,
            radius: 4,
            x: -2,
            y: -2
        )
    }
}

struct NeumorphicSegmentButton: View {
    let isSelected: Bool
    let label: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .medium : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NeumorphicSpacing.sm)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: NeumorphicRadius.sm)
                            .fill(Color.neumorphicSurface)
                            .shadow(
                                color: Color.neumorphicLightShadow,
                                radius: 4,
                                x: -2,
                                y: -2
                            )
                            .shadow(
                                color: Color.neumorphicDarkShadow,
                                radius: 4,
                                x: 2,
                                y: 2
                            )
                    }
                }
            )
            .foregroundStyle(isSelected ? Color.accentOrangeStart : Color.neumorphicTextSecondary)
            .animation(nil, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Simple Segment Control (Horizontal Pills)

struct NeumorphicPillSegmentControl<T: Hashable>: View {
    let options: [T]
    @Binding var selection: T
    let label: (T) -> String

    var body: some View {
        HStack(spacing: NeumorphicSpacing.xs) {
            ForEach(options, id: \.self) { option in
                NeumorphicPillButton(
                    label: label(option),
                    isSelected: selection == option
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = option
                    }
                }
            }
        }
    }
}

struct NeumorphicPillButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : Color.neumorphicTextSecondary)
                .padding(.horizontal, NeumorphicSpacing.md)
                .padding(.vertical, NeumorphicSpacing.xs)
                .background(pillBackground)
        }
        .buttonStyle(.plain)
        .neumorphicShadow(isPressed: isSelected, subtle: true)
    }

    @ViewBuilder
    private var pillBackground: some View {
        if isSelected {
            Capsule().fill(Color.orangeGradient)
        } else {
            Capsule().fill(Color.neumorphicSurface)
        }
    }
}

#Preview {
    ZStack {
        Color.neumorphicBackground.ignoresSafeArea()

        VStack(spacing: 40) {
            NeumorphicSegmentedControl(
                options: ["Photo", "Voice", "Text", "AI"],
                selection: .constant("Text"),
                label: { $0 },
                icon: { option in
                    switch option {
                    case "Photo": return "camera.fill"
                    case "Voice": return "mic.fill"
                    case "Text": return "text.alignleft"
                    case "AI": return "sparkles"
                    default: return "circle"
                    }
                }
            )
            .padding(.horizontal)

            NeumorphicPillSegmentControl(
                options: ["All", "Active", "Completed"],
                selection: .constant("All"),
                label: { $0 }
            )
        }
    }
}
