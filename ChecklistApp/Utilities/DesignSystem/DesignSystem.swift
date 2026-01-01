import SwiftUI

// MARK: - Color Extension for Adaptive Colors

extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

// MARK: - Neumorphic Colors

extension Color {
    // MARK: - Background Colors
    static let neumorphicBackground = Color(
        light: Color(red: 0.93, green: 0.93, blue: 0.91),
        dark: Color(red: 0.16, green: 0.16, blue: 0.18)
    )

    static let neumorphicSurface = Color(
        light: Color(red: 0.95, green: 0.95, blue: 0.93),
        dark: Color(red: 0.20, green: 0.20, blue: 0.22)
    )

    // MARK: - Shadow Colors
    static let neumorphicLightShadow = Color(
        light: Color.white.opacity(0.7),
        dark: Color(red: 0.25, green: 0.25, blue: 0.28).opacity(0.5)
    )

    static let neumorphicDarkShadow = Color(
        light: Color(red: 0.75, green: 0.73, blue: 0.70).opacity(0.5),
        dark: Color.black.opacity(0.6)
    )

    // MARK: - Orange Accent Gradient
    static let accentOrangeStart = Color(red: 1.0, green: 0.55, blue: 0.25)
    static let accentOrangeEnd = Color(red: 1.0, green: 0.40, blue: 0.40)

    static var orangeGradient: LinearGradient {
        LinearGradient(
            colors: [accentOrangeStart, accentOrangeEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Text Colors
    static let neumorphicTextPrimary = Color(
        light: Color.black.opacity(0.85),
        dark: Color.white.opacity(0.9)
    )

    static let neumorphicTextSecondary = Color(
        light: Color.black.opacity(0.55),
        dark: Color.white.opacity(0.6)
    )

    static let neumorphicTextTertiary = Color(
        light: Color.black.opacity(0.35),
        dark: Color.white.opacity(0.4)
    )

    // MARK: - Status Colors
    static let statusSuccess = Color(red: 0.30, green: 0.75, blue: 0.45)
    static let statusWarning = Color(red: 1.0, green: 0.65, blue: 0.25)
    static let statusError = Color(red: 0.95, green: 0.35, blue: 0.35)
    static let statusInfo = Color(red: 0.35, green: 0.60, blue: 0.90)

    // MARK: - Priority Colors (Neumorphic)
    static let priorityHighNeu = Color(red: 0.95, green: 0.35, blue: 0.35)
    static let priorityMediumNeu = Color(red: 1.0, green: 0.55, blue: 0.25)
    static let priorityLowNeu = Color(red: 0.30, green: 0.75, blue: 0.45)
}

// MARK: - Spacing Tokens

enum NeumorphicSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Radius Tokens

enum NeumorphicRadius {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let full: CGFloat = 9999
}

// MARK: - Shadow Definitions

enum NeumorphicShadow {
    // Raised (default) shadows
    static let lightOffset = CGSize(width: -6, height: -6)
    static let darkOffset = CGSize(width: 6, height: 6)
    static let lightRadius: CGFloat = 10
    static let darkRadius: CGFloat = 10

    // Subtle shadows for smaller elements
    static let subtleLightOffset = CGSize(width: -3, height: -3)
    static let subtleDarkOffset = CGSize(width: 3, height: 3)
    static let subtleRadius: CGFloat = 6

    // Pressed (inset) shadows
    static let pressedLightOffset = CGSize(width: 3, height: 3)
    static let pressedDarkOffset = CGSize(width: -3, height: -3)
    static let pressedRadius: CGFloat = 5
}
