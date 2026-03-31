import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    var buttonAction: () -> Void

    var body: some View {
        AppCard {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(Color.planGreen)
                    .frame(width: 72, height: 72)
                    .background(Color.planGreen.opacity(0.12), in: Circle())

                Text(title)
                    .font(.title3.weight(.bold))

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                PrimaryButton(title: buttonTitle, icon: "plus", action: buttonAction)
            }
        }
    }
}
