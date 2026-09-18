import SwiftUI

/// The user-selected appearance override. `system` intentionally leaves the
/// color scheme unspecified so macOS remains the source of truth.
enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
