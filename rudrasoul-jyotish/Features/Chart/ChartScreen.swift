import SwiftUI

struct ChartScreen: View {
    @Bindable var model: ChartScreenModel

    var body: some View {
        NavigationSplitView {
            ChartSidebar(selection: $model.destination)
                .navigationSplitViewColumnWidth(
                    min: DesignSize.sidebarMinimumWidth,
                    ideal: DesignSize.sidebarIdealWidth,
                    max: DesignSize.sidebarMaximumWidth
                )
        } detail: {
            ChartWorkspace(model: model)
        }
        .inspector(isPresented: $model.isInspectorPresented) {
            ChartInspector(chart: model.inspectorChartDetail)
                .inspectorColumnWidth(
                    min: DesignSize.inspectorMinimumWidth,
                    ideal: DesignSize.inspectorIdealWidth,
                    max: DesignSize.inspectorMaximumWidth
                )
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                if isChartPage {
                    activeChartSelectorMenu
                }
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    model.isPresentingNewChart = true
                } label: {
                    Label("library.toolbar.newChart", systemImage: "plus")
                }
                .help("New chart (⌘N)")

                if isChartPage {
                    if model.isRecalculating {
                        ProgressView()
                            .controlSize(.small)
                            .help("Recalculating…")
                    } else {
                        Button("Recalculate", systemImage: "arrow.clockwise") {
                            model.recalculateActiveChart()
                        }
                        .help("Recalculate this chart with the current engine (⇧⌘R)")
                        .disabled(model.chartDetail == nil)
                    }

                    Button("chart.toolbar.share", systemImage: "square.and.arrow.up") {}
                        .disabled(true)

                    Button("chart.toolbar.print", systemImage: "printer") {}
                        .disabled(true)
                }

                Button("chart.toolbar.inspector", systemImage: "sidebar.right") {
                    model.isInspectorPresented.toggle()
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
            }
        }
        .sheet(isPresented: $model.isPresentingNewChart) {
            NewChartSheet { newChart in
                model.openChart(newChart.id)
            }
        }
        .alert("Recalculation failed", isPresented: recalculationErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.recalculationError ?? "")
        }
    }

    private var isChartPage: Bool {
        model.destination?.isChartPage ?? false
    }

    private var recalculationErrorBinding: Binding<Bool> {
        Binding(
            get: { model.recalculationError != nil },
            set: { if !$0 { model.recalculationError = nil } }
        )
    }

    /// Quick switch between library charts; picking one opens (or focuses) its tab.
    private var activeChartSelectorMenu: some View {
        Menu {
            ForEach(model.charts) { chart in
                Button {
                    model.openChart(chart.id)
                } label: {
                    HStack {
                        Text(chart.name)
                        if chart.id == model.activeChartID {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            Divider()
            Button("New Chart…") {
                model.isPresentingNewChart = true
            }
        } label: {
            HStack(spacing: 4) {
                Text(model.chartDetail?.name ?? "Select Chart")
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignColor.primaryText)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(DesignColor.secondaryText)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(DesignColor.groupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .menuStyle(.borderlessButton)
        .help("Open another chart in a tab")
    }
}

private struct ChartSidebar: View {
    @Binding var selection: ChartScreenModel.Destination?

    var body: some View {
        List(selection: $selection) {
            Section("library.sidebar.section") {
                ForEach(ChartScreenModel.Destination.library, id: \.self) { destination in
                    destinationLabel(destination)
                }
            }
            Section("chart.sidebar.analysis") {
                ForEach(ChartScreenModel.Destination.analysis, id: \.self) { destination in
                    destinationLabel(destination)
                }
            }
            Section("chart.sidebar.chakras") {
                ForEach(ChartScreenModel.Destination.chakras, id: \.self) { destination in
                    destinationLabel(destination)
                }
            }
            Section("chart.sidebar.tools") {
                ForEach(ChartScreenModel.Destination.tools, id: \.self) { destination in
                    destinationLabel(destination)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("library.title")
    }

    private func destinationLabel(_ destination: ChartScreenModel.Destination) -> some View {
        Label(
            LocalizedStringKey(destination.titleKey),
            systemImage: destination.systemImage
        )
        .tag(destination)
    }
}

/// The detail column: the tab strip, then the library, the settings, or the analysis page
/// of the selected tab's chart.
private struct ChartWorkspace: View {
    @Bindable var model: ChartScreenModel
    @State private var pendingDeletion: LibraryChartDisplayData?

    var body: some View {
        VStack(spacing: 0) {
            if !model.tabs.isEmpty {
                ChartTabStrip(
                    items: model.tabs.map { ChartTabStrip.Item(id: $0.id, title: model.title(for: $0)) },
                    selectedID: model.highlightedTabID,
                    isLibrarySelected: model.isLibraryView,
                    onSelectLibrary: { model.showLibrary() },
                    onSelect: { model.selectTab($0) },
                    onClose: { model.closeTab($0) },
                    onCloseOthers: { model.closeOtherTabs(keeping: $0) },
                    onNewChart: { model.isPresentingNewChart = true }
                )
            }

            if model.isLibraryView {
                LibraryWorkspace(model: model, pendingDeletion: $pendingDeletion)
            } else if currentDestination == .settings {
                SettingsScreen(isEmbedded: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let chart = model.chartDetail {
                ChartIdentityHeader(
                    title: LocalizedStringKey(chart.name),
                    subtitle: LocalizedStringKey(headerSubtitle(for: chart))
                )

                destinationView(for: currentDestination, chart: chart)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(chart.id)
                    .environment(\.recalculateChart, { model.recalculateActiveChart() })

                AppStatusBar(
                    leadingText: LocalizedStringKey("Ayanamsa: \(chart.ayanamsaName) · \(chart.nodeCalculation)"),
                    trailingText: LocalizedStringKey("Swiss Ephemeris · \(chart.houseSystemName ?? "Whole Sign") bhavas")
                )
            } else {
                unavailableView
            }
        }
        .background(DesignColor.background)
        .navigationTitle(LocalizedStringKey(currentDestination.titleKey))
        .confirmationDialog(
            "Delete this chart?",
            isPresented: deletionBinding,
            titleVisibility: .visible
        ) {
            Button("Delete Chart", role: .destructive) {
                if let pendingDeletion {
                    model.deleteChart(id: pendingDeletion.id)
                }
                pendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDeletion = nil
            }
        } message: {
            Text("“\(pendingDeletion?.name ?? "")” and its notes and predictions are removed from the library. This cannot be undone.")
        }
    }

    private var deletionBinding: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )
    }

    private var currentDestination: ChartScreenModel.Destination {
        model.destination ?? .allCharts
    }

    /// Birth time, place, and ayanamsa; the ayanamsa value is omitted when the chart predates its calculation.
    private func headerSubtitle(for chart: ChartDetail) -> String {
        var parts = [chart.birthTimeString, chart.locationName]
        if let vara = chart.vara {
            parts.append(vara.name)
        }
        let ayanamsa = chart.ayanamsaValueDMS.isEmpty
            ? chart.ayanamsaName
            : "\(chart.ayanamsaName) (\(chart.ayanamsaValueDMS))"
        parts.append(ayanamsa)
        return parts.joined(separator: " · ")
    }

    private var unavailableView: some View {
        Group {
            ChartIdentityHeader(
                title: "chart.header.unavailable.title",
                subtitle: "chart.header.unavailable.subtitle"
            )
            ContentUnavailableView {
                Label(LocalizedStringKey(currentDestination.titleKey), systemImage: currentDestination.systemImage)
            } description: {
                Text("chart.workspace.unavailable.description")
            } actions: {
                Button("Show Library") {
                    model.showLibrary()
                }
                .buttonStyle(.borderedProminent)
                Button("New Chart…") {
                    model.isPresentingNewChart = true
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            AppStatusBar(
                leadingText: "chart.status.settingsUnavailable",
                trailingText: "chart.status.dataUnavailable"
            )
        }
    }

    @ViewBuilder
    private func destinationView(for destination: ChartScreenModel.Destination, chart: ChartDetail) -> some View {
        switch destination {
        case .allCharts, .recent, .settings:
            EmptyView()
        case .overview:
            OverviewView(chart: chart)
        case .divisionalCharts:
            DivisionalChartsView(chart: chart)
        case .planetsAndHouses:
            PlanetsAndHousesView(chart: chart)
        case .strength:
            StrengthView(chart: chart)
        case .ashtakavarga:
            AshtakavargaView(chart: chart)
        case .dasha:
            DashaView(chart: chart)
        case .nakshatra:
            NakshatraView(chart: chart)
        case .yogasAndDoshas:
            YogasAndDoshasView(chart: chart)
        case .jaimini:
            JaiminiView(chart: chart)
        case .sarvatobhadra:
            SarvatobhadraView(chart: chart)
        case .kota:
            KotaView(chart: chart)
        case .progressionAndTransit:
            ProgressionTransitView(chart: chart)
        case .notesAndPredictions:
            NotesPredictionsView(chart: chart, onUpdate: { model.store.saveChart(detail: $0) })
        }
    }
}
