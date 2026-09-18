import SwiftUI

enum DesignColor {
    static let accent = Color.accentColor
    static let primaryText = Color("InkPrimary")
    static let secondaryText = Color("InkSecondary")
    static let background = Color("SurfaceCanvas")
    static let groupedBackground = Color("SurfaceFill")
    static let separator = Color("Hairline")
    static let natal = Color("Natal")
    static let transit = Color("Transit")
    static let malefic = Color("Malefic")
    static let benefic = Color("Benefic")
    static let warning = Color("Warning")
}

enum DesignSpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let xLarge: CGFloat = 32
}

enum DesignTextStyle {
    case title
    case section
    case body
    case caption

    var font: Font {
        switch self {
        case .title:
            .title2.weight(.semibold)
        case .section:
            .headline
        case .body:
            .body
        case .caption:
            .caption
        }
    }
}

private struct DesignTextStyleModifier: ViewModifier {
    let style: DesignTextStyle
    let usesMonospacedDigits: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if usesMonospacedDigits {
            content
                .font(style.font)
                .monospacedDigit()
        } else {
            content.font(style.font)
        }
    }
}

extension View {
    func designTextStyle(
        _ style: DesignTextStyle,
        monospacedDigits: Bool = false
    ) -> some View {
        modifier(
            DesignTextStyleModifier(
                style: style,
                usesMonospacedDigits: monospacedDigits
            )
        )
    }
}
