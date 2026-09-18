import SwiftUI
import Testing
@testable import rudrasoul_jyotish

@MainActor
struct AppThemeTests {
    @Test func systemThemeDoesNotOverrideMacOSAppearance() {
        #expect(AppTheme.system.colorScheme == nil)
    }

    @Test func explicitThemesMapToTheirMatchingColorSchemes() {
        #expect(AppTheme.light.colorScheme == .light)
        #expect(AppTheme.dark.colorScheme == .dark)
    }
}
