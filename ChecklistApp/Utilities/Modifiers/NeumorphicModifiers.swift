import SwiftUI
import UIKit

// MARK: - Neumorphic Shadow Modifier

struct NeumorphicShadowModifier: ViewModifier {
    let isPressed: Bool
    var subtle: Bool = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: isPressed ? Color.neumorphicDarkShadow : Color.neumorphicLightShadow,
                radius: subtle ? NeumorphicShadow.subtleRadius : NeumorphicShadow.lightRadius,
                x: isPressed
                    ? NeumorphicShadow.pressedLightOffset.width
                    : (subtle ? NeumorphicShadow.subtleLightOffset.width : NeumorphicShadow.lightOffset.width),
                y: isPressed
                    ? NeumorphicShadow.pressedLightOffset.height
                    : (subtle ? NeumorphicShadow.subtleLightOffset.height : NeumorphicShadow.lightOffset.height)
            )
            .shadow(
                color: isPressed ? Color.neumorphicLightShadow : Color.neumorphicDarkShadow,
                radius: subtle ? NeumorphicShadow.subtleRadius : NeumorphicShadow.darkRadius,
                x: isPressed
                    ? NeumorphicShadow.pressedDarkOffset.width
                    : (subtle ? NeumorphicShadow.subtleDarkOffset.width : NeumorphicShadow.darkOffset.width),
                y: isPressed
                    ? NeumorphicShadow.pressedDarkOffset.height
                    : (subtle ? NeumorphicShadow.subtleDarkOffset.height : NeumorphicShadow.darkOffset.height)
            )
    }
}

// MARK: - Neumorphic Background Modifier

struct NeumorphicBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.neumorphicBackground.ignoresSafeArea())
    }
}

// MARK: - Neumorphic Card Modifier

struct NeumorphicCardModifier: ViewModifier {
    var cornerRadius: CGFloat = NeumorphicRadius.lg

    func body(content: Content) -> some View {
        content
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

// MARK: - Neumorphic Inset Modifier

struct NeumorphicInsetModifier: ViewModifier {
    var cornerRadius: CGFloat = NeumorphicRadius.md

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
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

// MARK: - Convenience Extensions

extension View {
    func neumorphicBackground() -> some View {
        modifier(NeumorphicBackgroundModifier())
    }

    func neumorphicCard(cornerRadius: CGFloat = NeumorphicRadius.lg) -> some View {
        modifier(NeumorphicCardModifier(cornerRadius: cornerRadius))
    }

    func neumorphicShadow(isPressed: Bool = false, subtle: Bool = false) -> some View {
        modifier(NeumorphicShadowModifier(isPressed: isPressed, subtle: subtle))
    }

    func neumorphicInset(cornerRadius: CGFloat = NeumorphicRadius.md) -> some View {
        modifier(NeumorphicInsetModifier(cornerRadius: cornerRadius))
    }

    @ViewBuilder
    func iPadExpandedModalLayout() -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self
                .presentationSizing(.page)
                .presentationCompactAdaptation(.none)
        } else {
            self
        }
    }
}
