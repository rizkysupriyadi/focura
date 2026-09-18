import SwiftUI

struct SettingsSectionView<Content: View>: View {
    let title: String
    let description: String?
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        description: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.description = description
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(FocuraColors.textPrimary)

                if let description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(FocuraColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, 16)

            content()
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(FocuraColors.border, lineWidth: 1)
        }
    }
}
