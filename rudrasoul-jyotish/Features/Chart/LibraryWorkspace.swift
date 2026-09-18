import SwiftUI

/// The library pages (All Charts, Recent): search and filters, the chart table, and the
/// open/delete actions. Double-clicking a row opens the chart in a tab.
struct LibraryWorkspace: View {
    @Bindable var model: ChartScreenModel
    /// Set to ask the workspace for a delete confirmation.
    @Binding var pendingDeletion: LibraryChartDisplayData?

    var body: some View {
        VStack(spacing: 0) {
            searchBar

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

            if model.charts.isEmpty {
                ContentUnavailableView {
                    Label("library.empty.title", systemImage: "rectangle.stack")
                } description: {
                    Text("library.empty.description")
                } actions: {
                    Button("New Chart…") {
                        model.isPresentingNewChart = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if model.visibleCharts.isEmpty {
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
                libraryTable
            }

            bottomBar
        }
    }

    // MARK: - Search and filters

    private var searchBar: some View {
        HStack(spacing: DesignSpacing.small) {
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
    }

    // MARK: - Table

    private var libraryTable: some View {
        Table(model.visibleCharts, selection: $model.selectedLibraryChartID) {
            TableColumn("library.column.name") { chart in
                HStack(spacing: 6) {
                    Image(systemName: model.tabs.contains(where: { $0.chartID == chart.id }) ? "macwindow" : "person.crop.circle")
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
        .contextMenu(forSelectionType: UUID.self, menu: { ids in
            if let id = ids.first {
                Button("Open in Tab") {
                    model.openChart(id)
                }
                Button("Recalculate Chart") {
                    model.recalculateChart(id: id)
                }
                Divider()
                Button(role: .destructive) {
                    pendingDeletion = model.charts.first(where: { $0.id == id })
                } label: {
                    Label("Delete Chart…", systemImage: "trash")
                }
            }
        }, primaryAction: { ids in
            if let id = ids.first {
                model.openChart(id)
            }
        })
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack {
            Text("library.status.count \(model.visibleCharts.count)")
                .designTextStyle(.caption, monospacedDigits: true)
                .foregroundStyle(DesignColor.secondaryText)

            Text("Double-click a chart to open it in a tab.")
                .designTextStyle(.caption)
                .foregroundStyle(DesignColor.secondaryText)

            Spacer()

            Button("Open in Tab") {
                if let selectedID = model.selectedLibraryChartID {
                    model.openChart(selectedID)
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
