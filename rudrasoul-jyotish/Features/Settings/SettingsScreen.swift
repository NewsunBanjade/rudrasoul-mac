
import SwiftUI

struct SettingsScreen: View {
    var isEmbedded: Bool = false

    @AppStorage("defaultAyanamsa") private var defaultAyanamsa = "Lahiri (Chitra Paksha)"
    @AppStorage("defaultLunarNode") private var defaultLunarNode = "True Node"
    @AppStorage("defaultHouseSystem") private var defaultHouseSystem = "Placidus"
    @AppStorage("dashaYearLength") private var dashaYearLength = "Solar (365.2422 days)"
    @AppStorage("defaultChartStyle") private var defaultChartStyle = "North Indian (Diamond)"
    @AppStorage("defaultCalendar") private var defaultCalendar = "A.D. (Gregorian)"
    @AppStorage("useDevanagariNumerals") private var useDevanagariNumerals = false
    @AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue

    var body: some View {
        if isEmbedded {
            VStack(spacing: DesignSpacing.medium) {
                tabViewContent
                    .frame(maxWidth: 680, minHeight: 380, maxHeight: 520)
                    .background(DesignColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(DesignColor.separator, lineWidth: 1)
                    )
                    .padding(DesignSpacing.large)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignColor.groupedBackground)
        } else {
            tabViewContent
                .frame(width: 480, height: 320)
                .padding(DesignSpacing.medium)
        }
    }

    private var tabViewContent: some View {
        TabView {
            calculationsTab
                .tabItem {
                    Label("Calculations", systemImage: "function")
                }

            displayTab
                .tabItem {
                    Label("Display", systemImage: "paintpalette")
                }

            ephemerisTab
                .tabItem {
                    Label("Ephemeris", systemImage: "globe.asia.australia")
                }
        }
    }

    private var calculationsTab: some View {
        Form {
            Picker("Default Ayanamsa", selection: $defaultAyanamsa) {
                Text("Lahiri (Chitra Paksha)").tag("Lahiri (Chitra Paksha)")
                Text("Raman").tag("Raman")
                Text("Krishnamurti (KP)").tag("Krishnamurti (KP)")
                Text("Fagan / Bradley").tag("Fagan / Bradley")
                Text("Tropical (Sayana)").tag("Tropical (Sayana)")
            }

            Picker("Lunar Node (Rahu/Ketu)", selection: $defaultLunarNode) {
                Text("True Node").tag("True Node")
                Text("Mean Node").tag("Mean Node")
            }

            Picker("Default House System", selection: $defaultHouseSystem) {
                Text("Placidus").tag("Placidus")
                Text("Sripati").tag("Sripati")
                Text("Equal Bhava").tag("Equal Bhava")
                Text("Whole Sign").tag("Whole Sign")
            }

            Picker("Dasha Year Length", selection: $dashaYearLength) {
                Text("Solar (365.2422 days)").tag("Solar (365.2422 days)")
                Text("Savana (360 days)").tag("Savana (360 days)")
            }
        }
        .formStyle(.grouped)
    }

    private var displayTab: some View {
        Form {
            Picker("Appearance", selection: $appTheme) {
                Text("System Default").tag(AppTheme.system.rawValue)
                Text("Light").tag(AppTheme.light.rawValue)
                Text("Dark").tag(AppTheme.dark.rawValue)
            }

            Picker("Default Chart Style", selection: $defaultChartStyle) {
                Text("North Indian (Diamond)").tag("North Indian (Diamond)")
                Text("South Indian (Square)").tag("South Indian (Square)")
            }

            Picker("Default Calendar", selection: $defaultCalendar) {
                Text("A.D. (Gregorian)").tag("A.D. (Gregorian)")
                Text("B.S. (Bikram Sambat)").tag("B.S. (Bikram Sambat)")
            }

            Toggle("Show Devanagari numerals in Nepali locale", isOn: $useDevanagariNumerals)
        }
        .formStyle(.grouped)
    }

    private var ephemerisTab: some View {
        Form {
            Section("Swiss Ephemeris Engine") {
                LabeledContent("Ephemeris Engine", value: "Swiss Ephemeris C (DE441/DE440)")
                LabeledContent("Version", value: "v2.10.03")
                LabeledContent("Ephemeris Path", value: "Bundled app resource")
                LabeledContent("Thread Safety", value: "Isolated Ephemeris Actor")
            }
        }
        .formStyle(.grouped)
    }
}
