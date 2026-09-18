import SwiftUI

/// Lets an analysis page ask the workspace to recalculate the chart it is showing, so that
/// "not computed" states can offer a one-click fix.
struct RecalculateChartActionKey: EnvironmentKey {
    static let defaultValue: (@MainActor () -> Void)? = nil
}

extension EnvironmentValues {
    var recalculateChart: (@MainActor () -> Void)? {
        get { self[RecalculateChartActionKey.self] }
        set { self[RecalculateChartActionKey.self] = newValue }
    }
}

/// The standard placeholder for a section whose data the stored chart does not carry yet.
struct StrengthUnavailableView: View {
    let title: LocalizedStringKey
    let systemImage: String
    let description: LocalizedStringKey

    @Environment(\.recalculateChart) private var recalculateChart

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
        } actions: {
            if let recalculateChart {
                Button("Recalculate Chart") {
                    recalculateChart()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
