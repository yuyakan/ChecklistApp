import SwiftUI

struct NeumorphicTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: NeumorphicSpacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(Color.neumorphicTextTertiary)
            }

            TextField(placeholder, text: $text)
                .foregroundStyle(Color.neumorphicTextPrimary)
        }
        .padding(NeumorphicSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: NeumorphicRadius.md)
                .fill(Color.neumorphicBackground)
                .shadow(
                    color: Color.neumorphicDarkShadow,
                    radius: 4,
                    x: 3,
                    y: 3
                )
                .shadow(
                    color: Color.neumorphicLightShadow,
                    radius: 4,
                    x: -3,
                    y: -3
                )
        )
    }
}

// MARK: - Neumorphic TextEditor

struct NeumorphicTextEditor: View {
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 150

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .foregroundStyle(Color.neumorphicTextPrimary)
                .padding(NeumorphicSpacing.sm)
                .frame(minHeight: minHeight)

            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(Color.neumorphicTextTertiary)
                    .padding(NeumorphicSpacing.md)
                    .allowsHitTesting(false)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: NeumorphicRadius.md)
                .fill(Color.neumorphicBackground)
                .shadow(
                    color: Color.neumorphicDarkShadow,
                    radius: 4,
                    x: 3,
                    y: 3
                )
                .shadow(
                    color: Color.neumorphicLightShadow,
                    radius: 4,
                    x: -3,
                    y: -3
                )
        )
    }
}

#Preview {
    ZStack {
        Color.neumorphicBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            NeumorphicTextField(
                placeholder: "Enter text...",
                text: .constant(""),
                icon: "magnifyingglass"
            )

            NeumorphicTextField(
                placeholder: "With text",
                text: .constant("Hello World")
            )

            NeumorphicTextEditor(
                text: .constant(""),
                placeholder: "Enter your notes here..."
            )
        }
        .padding()
    }
}
