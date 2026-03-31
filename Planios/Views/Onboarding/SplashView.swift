import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.82
    @State private var opacity = 0.15

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.planGreenDark, Color.planGreen, Color.planMint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.white.opacity(0.16))
                        .frame(width: 116, height: 116)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.white)
                }

                Text("Planios")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Plan. Focus. Finish.")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.82)) {
                scale = 1
                opacity = 1
            }
        }
    }
}
