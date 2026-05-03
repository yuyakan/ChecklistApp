import SwiftUI

struct NeumorphicProgressBar: View {
    let progress: Double
    var height: CGFloat = 8
    var showPercentage: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Inset track
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.neumorphicBackground)
                    .shadow(
                        color: Color.neumorphicDarkShadow,
                        radius: 2,
                        x: 1,
                        y: 1
                    )
                    .shadow(
                        color: Color.neumorphicLightShadow,
                        radius: 2,
                        x: -1,
                        y: -1
                    )

                // Progress fill
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.orangeGradient)
                    .frame(width: max(geometry.size.width * min(max(progress, 0), 1), height))
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Circular Progress

struct NeumorphicCircularProgress: View {
    let progress: Double
    var size: CGFloat = 100
    var lineWidth: CGFloat = 12

    var body: some View {
        ZStack {
            // Background circle (inset)
            Circle()
                .stroke(Color.neumorphicBackground, lineWidth: lineWidth)
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

            // Progress arc
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    Color.orangeGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Percentage text
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.neumorphicTextPrimary)

                Text("完了")
                    .font(.caption)
                    .foregroundStyle(Color.neumorphicTextSecondary)
            }
        }
        .frame(width: size, height: size)
    }
}

#if false
#Preview {
    ZStack {
        Color.neumorphicBackground.ignoresSafeArea()

        VStack(spacing: 40) {
            VStack(spacing: 16) {
                NeumorphicProgressBar(progress: 0.3)
                NeumorphicProgressBar(progress: 0.6)
                NeumorphicProgressBar(progress: 1.0)
            }
            .padding(.horizontal, 40)

            NeumorphicCircularProgress(progress: 0.65)
        }
    }
}
#endif
