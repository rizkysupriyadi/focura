import SwiftUI

enum FocuraTypography {
    static let pageTitle = Font.system(
        size: 32,
        weight: .semibold,
        design: .default
    )

    static let sectionTitle = Font.system(
        size: 20,
        weight: .semibold,
        design: .default
    )

    static let body = Font.system(
        size: 16,
        weight: .regular,
        design: .default
    )

    static let bodyMedium = Font.system(
        size: 16,
        weight: .medium,
        design: .default
    )

    static let caption = Font.system(
        size: 13,
        weight: .regular,
        design: .default
    )

    static let captionMedium = Font.system(
        size: 13,
        weight: .medium,
        design: .default
    )

    static let timer = Font.system(
        size: 72,
        weight: .medium,
        design: .monospaced
    )
}
