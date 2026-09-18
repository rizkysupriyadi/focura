import SwiftUI

struct SettingsRowView<Destination: View>: View {
    let title: String
    let value: String
    let destination: () -> Destination

    init(
        title: String,
        value: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.title = title
        self.value = value
        self.destination = destination
    }

    var body: some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FocuraColors.textPrimary)

                Spacer()

                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(FocuraColors.textSecondary)
            }
            .contentShape(Rectangle())
        }
        .padding(.vertical, 12)
    }
}
