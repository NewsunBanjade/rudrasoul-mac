import SwiftUI

/// The Dasha page: system picker, target date, proportional mahadasha strip,
/// hierarchical period table, on-demand Sookshma/Prana drill-down for
/// Vimshottari, and an inspector with chart-derived facts.
struct DashaView: View {
    let chart: ChartDetail

    @State private var targetDate = Date()
    @State private var selectedSystem: DashaSystem = .vimshottari
    @State private var selectedRowID: UUID? = nil
    @State private var isInspectorPresented = true

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                topBar
                Divider()
                if selectedSystem != .vimshottari, selectedTimeline == nil {
                    ContentUnavailableView(
                        "\(selectedSystem.rawValue) dasha not computed",
                        systemImage: "clock.badge.questionmark",
                        description: Text("Recompute the chart to add this dasha system.")
                    )
                } else {
                    content
                }
            }
            .frame(minWidth: 480, maxWidth: .infinity)

            if isInspectorPresented {
                DashaInspectorPanel(
                    chart: chart,
                    item: inspectorItem,
                    showsActivePeriod: selectedItem == nil
                )
                .frame(minWidth: 240, idealWidth: 280, maxWidth: 340)
            }
        }
        .onChange(of: selectedSystem) {
            selectedRowID = nil
        }
    }

    // MARK: - Derived state

    /// Birth instant every age and balance is measured from.
    private var birthDate: Date { chart.utcBirthDate ?? chart.birthDate }

    private var selectedTimeline: DashaTimeline? {
        chart.alternativeDashaTimelines.first { $0.system == selectedSystem }
    }

    private var yearLengthDays: Double {
        selectedTimeline?.yearLengthDays ?? VimshottariDashaCalculator.solarYearLengthDays
    }

    private var rows: [DashaRowItem] {
        if selectedSystem == .vimshottari {
            return DashaRowBuilder.rows(from: chart.dashaNodes, birthDate: birthDate, targetDate: targetDate, yearLengthDays: yearLengthDays)
        }
        guard let timeline = selectedTimeline else { return [] }
        return DashaRowBuilder.rows(from: timeline.periods, birthDate: birthDate, targetDate: targetDate, yearLengthDays: yearLengthDays)
    }

    private var activePath: [DashaRowItem] {
        DashaRowBuilder.activePath(in: rows, at: targetDate)
    }

    private var selectedItem: DashaRowItem? {
        guard let selectedRowID else { return nil }
        return DashaRowBuilder.row(withID: selectedRowID, in: rows)
    }

    private var inspectorItem: DashaRowItem? {
        selectedItem ?? activePath.last
    }

    private var activeVectorText: String {
        activePath.map(\.name).joined(separator: " › ")
    }

    private func isAvailable(_ system: DashaSystem) -> Bool {
        system == .vimshottari || chart.alternativeDashaTimelines.contains { $0.system == system }
    }

    /// "Moon in Revati (Mercury) · Mercury balance 4y 2m 3d" for Vimshottari; the stored note otherwise.
    private var derivationCaption: String {
        if let timeline = selectedTimeline {
            return timeline.derivationNote
        }
        guard let moon = chart.planets.first(where: { $0.graha == .moon }),
              let firstNode = chart.dashaNodes.first
        else { return "" }
        let balanceDays = firstNode.endDate.timeIntervalSince(birthDate) / 86_400
        let balance = VimshottariDashaCalculator.formattedDuration(days: balanceDays, yearLengthDays: yearLengthDays)
        return "Moon in \(moon.nakshatra.name) (\(moon.nakshatra.lord.rawValue)) · \(firstNode.lord.rawValue) balance \(balance)"
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack(spacing: DesignSpacing.small) {
            Picker("System", selection: $selectedSystem) {
                ForEach(DashaSystem.allCases) { system in
                    Text(system.rawValue)
                        .tag(system)
                        .disabled(!isAvailable(system))
                        .help(isAvailable(system) ? "" : "Not computed for this chart")
                }
            }
            .pickerStyle(.menu)
            .controlSize(.small)
            .fixedSize()

            Text(derivationCaption)
                .designTextStyle(.caption, monospacedDigits: true)
                .foregroundStyle(DesignColor.secondaryText)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: DesignSpacing.small)

            TransitDateStepper(date: $targetDate)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isInspectorPresented.toggle()
                }
            } label: {
                Image(systemName: "sidebar.right")
                    .foregroundStyle(isInspectorPresented ? DesignColor.accent : DesignColor.secondaryText)
            }
            .buttonStyle(.plain)
            .help(isInspectorPresented ? "Hide dasha inspector" : "Show dasha inspector")
        }
        .padding(.horizontal, DesignSpacing.medium)
        .padding(.vertical, DesignSpacing.small)
        .background(DesignColor.groupedBackground)
    }

    private var content: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Mahadasha continuum")
                        .designTextStyle(.section)
                    Spacer()
                    Text(activeVectorText.isEmpty ? "No period at target date" : "Active: \(activeVectorText)")
                        .designTextStyle(.caption, monospacedDigits: true)
                        .foregroundStyle(DesignColor.accent)
                        .lineLimit(1)
                }
                DashaContinuumStrip(rows: rows, targetDate: targetDate, selectedRowID: $selectedRowID)
            }
            .padding(DesignSpacing.medium)

            VSplitView {
                DashaTreeTable(rows: rows, selectedRowID: $selectedRowID)
                    .frame(minHeight: 160)

                if selectedSystem == .vimshottari {
                    DashaDrilldownView(chart: chart, birthDate: birthDate, targetDate: targetDate)
                        .frame(minHeight: 120, idealHeight: 240)
                }
            }
        }
        .background(DesignColor.background)
    }
}
