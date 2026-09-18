import SwiftUI

struct LibraryScreen: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable var model: LibraryScreenModel

    @State private var isPresentingNewChart = false

    var body: some View {
        NavigationSplitView {
            List(selection: $model.destination) {
                Section("library.sidebar.section") {
                    Label("library.sidebar.allCharts", systemImage: "rectangle.stack")
                        .tag(LibraryScreenModel.Destination.allCharts)
                    Label("library.sidebar.recent", systemImage: "clock")
                        .tag(LibraryScreenModel.Destination.recent)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(
                min: DesignSize.sidebarMinimumWidth,
                ideal: DesignSize.sidebarIdealWidth,
                max: DesignSize.sidebarMaximumWidth
            )
            .navigationTitle("library.title")
        } detail: {
            LibraryContent(model: model)
                .navigationTitle("library.allCharts.title")
        }
        .searchable(
            text: $model.searchText,
            placement: .toolbar,
            prompt: Text("library.search.prompt")
        )
        .task {
            await model.load()
        }
        .toolbar {

            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    model.isFilterPopoverPresented.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: model.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundStyle(model.hasActiveFilters ? DesignColor.accent : DesignColor.secondaryText)
                        Text("Filter")
                        if model.hasActiveFilters {
                            Text("\(model.activeFilterCount)")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(DesignColor.accent)
                                .foregroundStyle(Color.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .popover(isPresented: $model.isFilterPopoverPresented, arrowEdge: .bottom) {
                    ChartFilterPopover(
                        selectedLagna: $model.filterLagna,
                        selectedMoonRasi: $model.filterMoonRasi,
                        selectedDashaLord: $model.filterDashaLord,
                        selectedGender: $model.filterGender,
                        onReset: { model.resetFilters() }
                    )
                }

                Button {
                    isPresentingNewChart = true
                } label: {
                    Label("library.toolbar.newChart", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])

                Button("library.toolbar.open", systemImage: "macwindow") {
                    guard let selectedChartID = model.selectedChartID else {
                        return
                    }
                    openWindow(value: selectedChartID)
                }
                .disabled(model.selectedChartID == nil)
                .keyboardShortcut(.return, modifiers: [.command])
            }
        }
        .sheet(isPresented: $isPresentingNewChart) {
            NewChartSheet { newChart in
                Task {
                    await model.load()
                    model.selectedChartID = newChart.id
                    openWindow(value: newChart.id)
                }
            }
        }
    }
}

private struct LibraryContent: View {
    @Bindable var model: LibraryScreenModel

    var body: some View {
        VStack(spacing: 0) {
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

            Group {
                if let errorMessage = model.errorMessage {
                    ContentUnavailableView(
                        "library.error.title",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if model.charts.isEmpty {
                    ContentUnavailableView(
                        "library.empty.title",
                        systemImage: "rectangle.stack",
                        description: Text("library.empty.description")
                    )
                } else if model.visibleCharts.isEmpty {
                    ContentUnavailableView {
                        Label("No Charts Match Filters", systemImage: "line.3.horizontal.decrease.circle")
                    } description: {
                        Text("Try clearing some astrological filters or changing your search query.")
                    } actions: {
                        Button("Reset Filters") {
                            model.searchText = ""
                            model.resetFilters()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    LibraryTable(model: model)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LibraryStatusBar(chartCount: model.chartCount)
        }
    }
}

private struct LibraryTable: View {
    @Bindable var model: LibraryScreenModel

    var body: some View {
        Table(model.visibleCharts, selection: $model.selectedChartID) {
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
        .accessibilityLabel("library.table.accessibilityLabel")
    }
}

private struct LibraryStatusBar: View {
    let chartCount: Int

    var body: some View {
        HStack {
            Text("library.status.count \(chartCount)")
                .designTextStyle(.caption, monospacedDigits: true)
                .foregroundStyle(DesignColor.secondaryText)
            Spacer()
        }
        .padding(.horizontal, DesignSpacing.small)
        .padding(.vertical, DesignSpacing.xSmall)
        .background(DesignColor.background)
        .overlay(alignment: .top) {
            Divider()
        }
        .accessibilityElement(children: .combine)
    }
}
