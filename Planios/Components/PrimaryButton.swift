import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    var isDisabled = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.planGreen, Color.planGreenDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
    }
}
