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
                if !model.isLibraryView && model.destination != .settings {
                    activeChartSelectorMenu
                }
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    model.isPresentingNewChart = true
                } label: {
                    Label("library.toolbar.newChart", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])

                if !model.isLibraryView && model.destination != .settings {
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
                model.selectAndOpenChart(newChart.id)
            }
        }
    }

    private var activeChartSelectorMenu: some View {
        Menu {
            ForEach(model.charts) { chart in
                Button {
                    model.selectAndOpenChart(chart.id)
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
            Button("+ New Chart...") {
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

private struct ChartWorkspace: View {
    @Bindable var model: ChartScreenModel

    var body: some View {
        VStack(spacing: 0) {
            if isLibraryView {
                libraryContentView
            } else if currentDestination == .settings {
                settingsContentView
            } else if let chart = model.chartDetail {
                ChartIdentityHeader(
                    title: LocalizedStringKey(chart.name),
                    subtitle: LocalizedStringKey(headerSubtitle(for: chart))
                )

                destinationView(for: currentDestination, chart: chart)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                AppStatusBar(
                    leadingText: LocalizedStringKey("Ayanamsa: \(chart.ayanamsaName) · \(chart.nodeCalculation)"),
                    trailingText: LocalizedStringKey("Swiss Ephemeris DE440 · Online")
                )
            } else {
                ChartIdentityHeader(
                    title: "chart.header.unavailable.title",
                    subtitle: "chart.header.unavailable.subtitle"
                )
                ContentUnavailableView(
                    LocalizedStringKey(currentDestination.titleKey),
                    systemImage: currentDestination.systemImage,
                    description: Text("chart.workspace.unavailable.description")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                AppStatusBar(
                    leadingText: "chart.status.settingsUnavailable",
                    trailingText: "chart.status.dataUnavailable"
                )
            }
        }
        .background(DesignColor.background)
        .navigationTitle(LocalizedStringKey(currentDestination.titleKey))
    }

    private var isLibraryView: Bool {
        currentDestination == .allCharts || currentDestination == .recent
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

    private var currentDestination: ChartScreenModel.Destination {
        model.destination ?? .overview
    }

    private var libraryContentView: some View {
        VStack(spacing: 0) {
            // Library Sub-header Toolbar with Search and Filter
            HStack(spacing: DesignSpacing.small) {
                // Search Input Field
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignColor.secondaryText)

                    TextField("library.search.prompt", text: $model.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))

                    if !model.searchText.isEmpty {
                        Button {
                            model.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(DesignColor.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .help("Clear search")
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(DesignColor.background)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(DesignColor.separator, lineWidth: 1)
                )
                .frame(minWidth: 200, idealWidth: 260, maxWidth: 340)

                // Filter Button with Badge
                Button {
                    model.isFilterPopoverPresented.toggle()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: model.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(model.hasActiveFilters ? DesignColor.accent : DesignColor.secondaryText)
                        Text("Filter")
                            .font(.system(size: 12, weight: .medium))
                        if model.hasActiveFilters {
                            Text("\(model.activeFilterCount)")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(DesignColor.accent)
                                .foregroundStyle(Color.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .popover(isPresented: $model.isFilterPopoverPresented, arrowEdge: .bottom) {
                    ChartFilterPopover(
                        selectedLagna: $model.filterLagna,
                        selectedMoonRasi: $model.filterMoonRasi,
                        selectedDashaLord: $model.filterDashaLord,
                        selectedGender: $model.filterGender,
                        onReset: { model.resetFilters() }
                    )
                }

                if model.hasActiveFilters || !model.searchText.isEmpty {
                    Button("Reset All") {
                        model.searchText = ""
                        model.resetFilters()
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
                }

                Spacer()

                Text("\(model.visibleCharts.count) of \(model.charts.count) Charts")
                    .designTextStyle(.caption, monospacedDigits: true)
                    .foregroundStyle(DesignColor.secondaryText)
            }
            .padding(.horizontal, DesignSpacing.small)
            .padding(.vertical, 6)
            .background(DesignColor.groupedBackground)
            .overlay(alignment: .bottom) { Divider() }

            // Active Filter Token Strip
            if model.hasActiveFilters {
                ActiveFilterTokenBar(
                    lagna: model.filterLagna,
                    moonRasi: model.filterMoonRasi,
                    dashaLord: model.filterDashaLord,
                    gender: model.filterGender,
                    onRemoveLagna: { model.filterLagna = nil },
                    onRemoveMoonRasi: { model.filterMoonRasi = nil },
                    onRemoveDashaLord: { model.filterDashaLord = nil },
                    onRemoveGender: { model.filterGender = nil },
                    onClearAll: { model.resetFilters() }
                )
            }

            if model.visibleCharts.isEmpty {
                ContentUnavailableView {
                    Label("No Charts Match Filters", systemImage: "line.3.horizontal.decrease.circle")
                } description: {
                    Text("Try adjusting your search terms or clearing astrological filters.")
                } actions: {
                    Button("Reset Filters") {
                        model.searchText = ""
                        model.resetFilters()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(model.visibleCharts, selection: $model.selectedLibraryChartID) {
                    TableColumn("library.column.name") { chart in
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.circle")
                                .foregroundStyle(DesignColor.accent)
                                .font(.system(size: 13))
                            Text(chart.name)
                                .designTextStyle(.body)
                                .fontWeight(.medium)
                        }
                    }
                    .width(min: 160, ideal: 190)

                    TableColumn("Lagna") { chart in
                        Text(chart.lagnaRasi ?? "—")
                            .designTextStyle(.body)
                            .foregroundStyle(DesignColor.primaryText)
                    }
                    .width(min: 80, ideal: 100)

                    TableColumn("Moon Star") { chart in
                        Text(chart.moonNakshatra ?? "—")
                            .designTextStyle(.body)
                            .foregroundStyle(DesignColor.secondaryText)
                    }
                    .width(min: 90, ideal: 110)

                    TableColumn("Running Dasha") { chart in
                        if let dasha = chart.currentDasha {
                            Text(dasha.components(separatedBy: "›").prefix(2).joined(separator: "› "))
                                .designTextStyle(.body, monospacedDigits: true)
                                .foregroundStyle(DesignColor.accent)
                        } else {
                            Text("—")
                                .designTextStyle(.body)
                                .foregroundStyle(DesignColor.secondaryText)
                        }
                    }
                    .width(min: 110, ideal: 130)

                    TableColumn("library.column.location") { chart in
                        Text(chart.location)
                            .designTextStyle(.body)
                            .foregroundStyle(DesignColor.secondaryText)
                    }
                    .width(min: 140, ideal: 180)

                    TableColumn("library.column.date") { chart in
                        Text(chart.localDate, format: .dateTime.year().month().day())
                            .designTextStyle(.body, monospacedDigits: true)
                    }
                    .width(min: 90, ideal: 100)
                }
                .contextMenu {
                    if let selectedID = model.selectedLibraryChartID {
                        Button("Open Chart in Overview") {
                            model.selectAndOpenChart(selectedID)
                        }
                        Divider()
                        Button(role: .destructive) {
                            model.deleteChart(id: selectedID)
                        } label: {
                            Label("Delete Chart", systemImage: "trash")
                        }
                    }
                }
            }

            // Bottom bar with chart count and Open Chart button
            HStack {
                Text("library.status.count \(model.visibleCharts.count)")
                    .designTextStyle(.caption, monospacedDigits: true)
                    .foregroundStyle(DesignColor.secondaryText)

                Spacer()

                Button("Open Chart") {
                    if let selectedID = model.selectedLibraryChartID {
                        model.selectAndOpenChart(selectedID)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(model.selectedLibraryChartID == nil)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, DesignSpacing.small)
            .padding(.vertical, DesignSpacing.xSmall)
            .background(DesignColor.background)
            .overlay(alignment: .top) { Divider() }
        }
    }

    private var settingsContentView: some View {
        SettingsScreen(isEmbedded: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            NotesPredictionsView(chart: chart)
        }
    }
}

private struct ChartInspector: View {
    let chart: ChartDetail?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.medium) {
            Text("chart.inspector.title")
                .designTextStyle(.section)

            if let chart {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSpacing.small) {
                        MetricTile(
                            title: "Native Subject",
                            value: chart.name,
                            subtitle: "\(chart.gender) · \(chart.calendarSystem)",
                            badge: "Natal"
                        )

                        MetricTile(
                            title: "Ascendant (Lagna)",
                            value: "\(chart.lagnaPosition.rasi.sanskritName) \(chart.lagnaPosition.formattedDMS)",
                            subtitle: "\(chart.lagnaPosition.nakshatra.name) Pada \(chart.lagnaPosition.pada)",
                            badge: "1st House"
                        )

                        MetricTile(
                            title: "Ayanamsa Offset",
                            value: chart.ayanamsaValueDMS,
                            subtitle: chart.ayanamsaName,
                            badge: "Sidereal"
                        )

                        MetricTile(
                            title: "Active Vimshottari Vector",
                            value: chart.currentDashaVector.components(separatedBy: "›").prefix(2).joined(separator: "› "),
                            subtitle: chart.currentDashaVector,
                            badge: "Running",
                            isAuspicious: true
                        )

                        Divider().padding(.vertical, DesignSpacing.xSmall)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Birth Coordinates")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            Text("\(chart.latitude), \(chart.longitude)")
                                .designTextStyle(.body, monospacedDigits: true)
                            Text(chart.timezoneString)
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                        }

                        Divider().padding(.vertical, DesignSpacing.xSmall)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Formed Yogas Count")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            Text("\(chart.yogas.count) Classical Combinations")
                                .designTextStyle(.body)
                                .fontWeight(.medium)
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "chart.inspector.unavailable.title",
                    systemImage: "info.circle",
                    description: Text("chart.inspector.unavailable.description")
                )
                Spacer()
            }
        }
        .padding(DesignSpacing.medium)
        .background(DesignColor.groupedBackground)
    }
}
