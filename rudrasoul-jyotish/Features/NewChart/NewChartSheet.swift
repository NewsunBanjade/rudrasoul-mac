import EphemerisKit
import SwiftUI

struct NewChartSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: ((ChartDetail) -> Void)?

    // Calculation defaults chosen in Settings.
    @AppStorage("defaultAyanamsa") private var defaultAyanamsa = "Lahiri (Chitra Paksha)"
    @AppStorage("defaultLunarNode") private var defaultLunarNode = "True Node"
    @AppStorage("defaultHouseSystem") private var defaultHouseSystem = "Whole Sign"

    @State private var name: String = ""
    @State private var gender: String = "Male"
    @State private var calendarSystem: String = "A.D. (Gregorian)"
    @State private var birthDate: Date = Date()
    @State private var birthHour: Int = 12
    @State private var birthMinute: Int = 0
    @State private var birthSecond: Int = 0
    @State private var isAM: Bool = true
    @State private var accuracy: String = "Exact (to second)"

    @State private var cityName: String = "Kathmandu, Nepal"
    @State private var latitude: String = "27° 42' 52\" N"
    @State private var longitude: String = "85° 19' 12\" E"
    @State private var timezone: String = "NST (Nepal Standard Time) UTC+05:45"
    @State private var isDST: Bool = false
    @State private var useLMTForHistorical: Bool = true

    @State private var chartStyle: String = "North Indian (Diamond)"
    @State private var notes: String = ""
    @State private var calculationError: String?
    @State private var isCalculating = false
    @State private var locationResults: [OpenStreetMapLocationSearch.Result] = []
    @State private var locationSearchError: String?
    @State private var isSearchingLocations = false

    var body: some View {
        VStack(spacing: 0) {
            // Sheet Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: DesignSpacing.small) {
                        Text("New Chart")
                            .designTextStyle(.title)
                        Text("D-1 Kundali")
                            .designTextStyle(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignColor.groupedBackground)
                            .clipShape(Capsule())
                    }
                    Text("Enter birth details and search OpenStreetMap for the birth location")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)
                }
                Spacer()
                Button("Esc closes") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .designTextStyle(.caption)
                .foregroundStyle(DesignColor.secondaryText)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, DesignSpacing.large)
            .padding(.vertical, DesignSpacing.medium)
            .background(DesignColor.background)
            .overlay(alignment: .bottom) { Divider() }

            // Form Body - Two columns
            ScrollView {
                HStack(alignment: .top, spacing: DesignSpacing.large) {
                    // Column 1: Birth Details & Location
                    VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                        SectionHeader(title: "Birth Details")

                        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                            Text("Subject Name")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            TextField("e.g., Siddhartha Gautam", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                            Text("Gender")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            Picker("", selection: $gender) {
                                Text("Male").tag("Male")
                                Text("Female").tag("Female")
                                Text("Other").tag("Other")
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }

                        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                            HStack {
                                Text("Date of Birth")
                                    .designTextStyle(.caption)
                                    .foregroundStyle(DesignColor.secondaryText)
                                Spacer()
                                Picker("", selection: $calendarSystem) {
                                    Text("A.D. (Gregorian)").tag("A.D. (Gregorian)")
                                    Text("B.S. (Bikram Sambat)").tag("B.S. (Bikram Sambat)")
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                                .controlSize(.small)
                            }
                            DatePicker("", selection: $birthDate, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.field)

                            // Live Bikram Sambat conversion callout
                            HStack {
                                Text("⇄")
                                Text(bikramSambatEquivalent)
                                    .font(.caption.monospaced())
                                Spacer()
                                Text(dayOfWeek)
                                    .designTextStyle(.caption)
                                    .foregroundStyle(DesignColor.secondaryText)
                            }
                            .padding(.horizontal, DesignSpacing.small)
                            .padding(.vertical, DesignSpacing.xSmall)
                            .background(DesignColor.groupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                            Text("Time of Birth & Accuracy")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            DatePicker("", selection: $birthDate, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .datePickerStyle(.field)

                            Picker("Accuracy", selection: $accuracy) {
                                Text("Exact (to second)").tag("Exact (to second)")
                                Text("± 5 Minutes").tag("± 5 Minutes")
                                Text("± 15 Minutes").tag("± 15 Minutes")
                                Text("Rectified").tag("Rectified")
                                Text("Approximate").tag("Approximate")
                            }
                            .controlSize(.small)
                        }

                        Divider()

                        SectionHeader(title: "Place of Birth")

                        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                            Text("City / OpenStreetMap Lookup")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            HStack(spacing: DesignSpacing.small) {
                                TextField("City name", text: $cityName)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit(searchLocations)

                                Button(action: searchLocations) {
                                    if isSearchingLocations {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Image(systemName: "magnifyingglass")
                                    }
                                }
                                .help("Search OpenStreetMap")
                                .disabled(isSearchingLocations)
                            }

                            if let locationSearchError {
                                Text(locationSearchError)
                                    .designTextStyle(.caption)
                                    .foregroundStyle(DesignColor.warning)
                            }

                            if !locationResults.isEmpty {
                                VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                                    ForEach(locationResults) { result in
                                        Button {
                                            selectLocation(result)
                                        } label: {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(result.displayName)
                                                    .lineLimit(2)
                                                Text("\(formattedCoordinate(result.latitude)), \(formattedCoordinate(result.longitude))")
                                                    .font(.caption.monospaced())
                                                    .foregroundStyle(DesignColor.secondaryText)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .buttonStyle(.plain)
                                        .padding(DesignSpacing.xSmall)
                                    }
                                }
                                .background(DesignColor.groupedBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }

                        HStack(spacing: DesignSpacing.small) {
                            VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                                Text("Latitude")
                                    .designTextStyle(.caption)
                                    .foregroundStyle(DesignColor.secondaryText)
                                TextField("Latitude", text: $latitude)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body.monospaced())
                            }
                            VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                                Text("Longitude")
                                    .designTextStyle(.caption)
                                    .foregroundStyle(DesignColor.secondaryText)
                                TextField("Longitude", text: $longitude)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body.monospaced())
                            }
                        }

                        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                            Text("Time Zone")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            Picker("", selection: $timezone) {
                                Text("NST (Nepal) UTC+05:45").tag("NST (Nepal Standard Time) UTC+05:45")
                                Text("IST (India) UTC+05:30").tag("IST (Indian Standard Time) UTC+05:30")
                                Text("LMT (Local Mean Time)").tag("LMT (Local Mean Time)")
                                Text("UTC (GMT)").tag("UTC")
                            }
                        }

                        Toggle("Daylight Saving Time (DST)", isOn: $isDST)
                            .designTextStyle(.caption)

                        Toggle("Use Local Mean Time (LMT) for pre-1906 epoch", isOn: $useLMTForHistorical)
                            .designTextStyle(.caption)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()

                    // Column 2: Display & Notes
                    VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                        SectionHeader(title: "Chart Display")

                        Text("\(selectedAyanamsaName) ayanamsa, \(selectedNodeName.lowercased()), and \(selectedHouseSystem.displayName.lowercased()) bhavas will be used. Change these defaults in Settings › Calculations.")
                            .designTextStyle(.caption)
                            .foregroundStyle(DesignColor.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                            Text("Chart Display Style")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            Picker("", selection: $chartStyle) {
                                Text("North Indian (Diamond)").tag("North Indian (Diamond)")
                                Text("South Indian (Square)").tag("South Indian (Square)")
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }

                        Divider()

                        SectionHeader(title: "Practitioner Notes")

                        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                            Text("Initial Observations")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            TextEditor(text: $notes)
                                .font(.body)
                                .frame(height: 120)
                                .border(DesignColor.separator, width: 1)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(DesignSpacing.large)
            }

            // Footer action bar
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)

                Button("Save & Open Chart") {
                    saveAndOpen()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCalculating)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, DesignSpacing.large)
            .padding(.vertical, DesignSpacing.medium)
            .background(DesignColor.groupedBackground)
            .overlay(alignment: .top) { Divider() }
        }
        .frame(minWidth: 780, idealWidth: 820, maxWidth: 900, minHeight: 600, maxHeight: 720)
        .background(DesignColor.background)
        .alert("Chart calculation failed", isPresented: Binding(
            get: { calculationError != nil },
            set: { if !$0 { calculationError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(calculationError ?? "")
        }
    }

    private var bikramSambatEquivalent: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: birthDate) + 57
        let month = calendar.component(.month, from: birthDate)
        let day = calendar.component(.day, from: birthDate)
        let bsMonths = ["Baisakh", "Jestha", "Ashadh", "Shrawan", "Bhadra", "Ashwin", "Kartik", "Mangsir", "Poush", "Magh", "Falgun", "Chaitra"]
        let monthName = bsMonths[(month + 8) % 12]
        // Year and month are offset only; verified Bikram Sambat tables are not wired in yet.
        return "\(day) \(monthName) \(year) B.S. (approx.)"
    }

    /// The ephemeris ayanamsa for the Settings default; unknown names fall back to Lahiri.
    private var selectedAyanamsa: Ayanamsa {
        let name = defaultAyanamsa.lowercased()
        if name.contains("raman") { return .raman }
        if name.contains("krishnamurti") || name.contains("kp") { return .krishnamurti }
        return .lahiri
    }

    private var selectedAyanamsaName: String {
        switch selectedAyanamsa {
        case .raman: return "Raman"
        case .krishnamurti: return "Krishnamurti (KP)"
        case .lahiri: return "Lahiri (Chitra Paksha)"
        }
    }

    private var selectedNodeCalculation: ChartCalculationInput.NodeCalculation {
        defaultLunarNode.lowercased().contains("mean") ? .meanNode : .trueNode
    }

    private var selectedNodeName: String {
        selectedNodeCalculation == .meanNode ? "Mean Node" : "True Node"
    }

    private var selectedHouseSystem: HouseSystem {
        HouseSystem(displayName: defaultHouseSystem) ?? .wholeSign
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: birthDate)
    }

    private func saveAndOpen() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeStr = formatter.string(from: birthDate)
        let input = ChartCalculationInput(
            id: UUID(), name: name.trimmingCharacters(in: .whitespacesAndNewlines), gender: gender,
            birthDate: birthDate, birthTimeString: timeStr, calendarSystem: calendarSystem,
            bikramSambatDateString: bikramSambatEquivalent, locationName: cityName, latitude: latitude,
            longitude: longitude, timezoneString: timezone, utcOffsetSeconds: timezoneOffsetSeconds,
            ayanamsaName: selectedAyanamsaName, ayanamsa: selectedAyanamsa,
            nodeCalculation: selectedNodeCalculation,
            houseSystem: selectedHouseSystem,
            notes: notes.isEmpty ? [] : [
                ChartNote(id: UUID(), date: Date(), category: "Initial Intake", content: notes, tags: ["#Intake"])
            ]
        )
        isCalculating = true
        Task {
            do {
                let detail = try await ChartCalculationService().calculate(input: input)
                ChartStore.shared.saveChart(detail: detail)
                onSave?(detail)
                dismiss()
            } catch {
                calculationError = error.localizedDescription
            }
            isCalculating = false
        }
    }

    private var timezoneOffsetSeconds: TimeInterval {
        switch timezone {
        case "NST (Nepal Standard Time) UTC+05:45": 20_700
        case "IST (Indian Standard Time) UTC+05:30": 19_800
        case "LMT (Local Mean Time)": (longitudeDecimalDegrees ?? 0) * 240
        default: 0
        }
    }

    private var longitudeDecimalDegrees: Double? {
        let values = longitude.split { !$0.isNumber && $0 != "." }.compactMap { Double($0) }
        guard let degrees = values.first else { return nil }
        return degrees + (values.count > 1 ? values[1] / 60 : 0) + (values.count > 2 ? values[2] / 3_600 : 0)
    }

    private func searchLocations() {
        let query = cityName
        isSearchingLocations = true
        locationSearchError = nil
        locationResults = []

        Task {
            do {
                locationResults = try await OpenStreetMapLocationSearch().search(query: query)
                if locationResults.isEmpty {
                    locationSearchError = "No matching locations were found. Try a more specific search."
                }
            } catch {
                locationSearchError = error.localizedDescription
            }
            isSearchingLocations = false
        }
    }

    private func selectLocation(_ result: OpenStreetMapLocationSearch.Result) {
        cityName = result.displayName
        latitude = formattedCoordinate(result.latitude)
        longitude = formattedCoordinate(result.longitude)
        locationResults = []
        locationSearchError = nil
    }

    private func formattedCoordinate(_ coordinate: Double) -> String {
        String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), coordinate)
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .designTextStyle(.section)
            .foregroundStyle(DesignColor.primaryText)
    }
}
