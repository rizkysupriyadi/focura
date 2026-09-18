import SwiftUI

struct FocuraPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FocuraTypography.bodyMedium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(FocuraColors.primary)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: FocuraRadius.large,
                    style: .continuous
                )
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(
                .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}


struct FocuraDarkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FocuraTypography.bodyMedium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(.black)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: FocuraRadius.large,
                    style: .continuous
                )
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(
                .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}

struct FocuraSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FocuraTypography.bodyMedium)
            .foregroundStyle(FocuraColors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(
                Color(uiColor: .secondarySystemBackground)
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: FocuraRadius.large,
                    style: .continuous
                )
                .stroke(
                    FocuraColors.border,
                    lineWidth: 1
                )
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: FocuraRadius.large,
                    style: .continuous
                )
            )
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(
                .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}
