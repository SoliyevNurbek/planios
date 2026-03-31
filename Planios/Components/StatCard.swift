import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let caption: String
    let icon: String
    let iconColor: Color

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: icon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
