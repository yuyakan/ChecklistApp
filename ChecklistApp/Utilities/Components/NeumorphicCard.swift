import SwiftUI

struct NeumorphicCard<Content: View>: View {
    let content: () -> Content
    var padding: CGFloat = NeumorphicSpacing.md
    var cornerRadius: CGFloat = NeumorphicRadius.lg

    init(
        padding: CGFloat = NeumorphicSpacing.md,
        cornerRadius: CGFloat = NeumorphicRadius.lg,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(Color.neumorphicSurface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: Color.neumorphicLightShadow,
                radius: NeumorphicShadow.lightRadius,
                x: NeumorphicShadow.lightOffset.width,
                y: NeumorphicShadow.lightOffset.height
            )
            .shadow(
                color: Color.neumorphicDarkShadow,
                radius: NeumorphicShadow.darkRadius,
                x: NeumorphicShadow.darkOffset.width,
                y: NeumorphicShadow.darkOffset.height
            )
    }
}

#if false
#Preview {
    ZStack {
        Color.neumorphicBackground.ignoresSafeArea()

        NeumorphicCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Title")
                    .font(.headline)
                Text("Card content goes here")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}
#endif
