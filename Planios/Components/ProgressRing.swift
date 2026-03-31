import SwiftUI

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 14
    var size: CGFloat = 116

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.planGreen.opacity(0.14), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(
                    LinearGradient(
                        colors: [Color.planGreen, Color.planGreenDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.45), value: progress)

            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Text("Done")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}
