import SwiftUI

struct NewChartSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: ((ChartDetail) -> Void)?

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

    @State private var ayanamsa: String = "Lahiri (Chitra Paksha)"
    @State private var nodeCalculation: String = "True Node"
    @State private var houseSystem: String = "Placidus"
    @State private var chartStyle: String = "North Indian (Diamond)"
    @State private var notes: String = ""

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
                    Text("Enter birth coordinates, temporal calendar, and calculation settings")
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
                            Text("City / Atlas Lookup")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            TextField("City name", text: $cityName)
                                .textFieldStyle(.roundedBorder)
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

                    // Column 2: Calculation Settings & Notes
                    VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                        SectionHeader(title: "Calculation Settings")

                        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                            Text("Ayanamsa")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            Picker("", selection: $ayanamsa) {
                                Text("Lahiri (Chitra Paksha)").tag("Lahiri (Chitra Paksha)")
                                Text("Raman").tag("Raman")
                                Text("Krishnamurti (KP)").tag("Krishnamurti (KP)")
                                Text("Fagan/Bradley").tag("Fagan/Bradley")
                                Text("Tropical (Sayana)").tag("Tropical (Sayana)")
                            }
                        }

                        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                            Text("Lunar Node (Rahu / Ketu)")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            Picker("", selection: $nodeCalculation) {
                                Text("True Node").tag("True Node")
                                Text("Mean Node").tag("Mean Node")
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }

                        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                            Text("Bhava / House System")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            Picker("", selection: $houseSystem) {
                                Text("Placidus").tag("Placidus")
                                Text("Sripati").tag("Sripati")
                                Text("Equal Bhava").tag("Equal Bhava")
                                Text("Whole Sign").tag("Whole Sign")
                            }
                        }

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
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, DesignSpacing.large)
            .padding(.vertical, DesignSpacing.medium)
            .background(DesignColor.groupedBackground)
            .overlay(alignment: .top) { Divider() }
        }
        .frame(minWidth: 780, idealWidth: 820, maxWidth: 900, minHeight: 600, maxHeight: 720)
        .background(DesignColor.background)
    }

    private var bikramSambatEquivalent: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: birthDate) + 57
        let month = calendar.component(.month, from: birthDate)
        let day = calendar.component(.day, from: birthDate)
        let bsMonths = ["Baisakh", "Jestha", "Ashadh", "Shrawan", "Bhadra", "Ashwin", "Kartik", "Mangsir", "Poush", "Magh", "Falgun", "Chaitra"]
        let monthName = bsMonths[(month + 8) % 12]
        return "\(day) \(monthName) \(year) B.S."
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: birthDate)
    }

    private func saveAndOpen() {
        let newID = UUID()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeStr = formatter.string(from: birthDate)

        let detail = ChartDetail(
            id: newID,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            gender: gender,
            birthDate: birthDate,
            birthTimeString: timeStr,
            calendarSystem: calendarSystem,
            bikramSambatDateString: bikramSambatEquivalent,
            locationName: cityName,
            latitude: latitude,
            longitude: longitude,
            timezoneString: timezone,
            ayanamsaName: ayanamsa,
            ayanamsaValueDMS: "24° 10' 15\"",
            nodeCalculation: nodeCalculation,
            sunriseString: "06:00 AM",
            sunsetString: "06:00 PM",
            lagnaPosition: PlanetPosition(
                graha: .ascendant,
                rasi: .aries,
                longitudeInRasi: 15.0,
                formattedDMS: "15° 00' 00\"",
                nakshatra: .bharani,
                pada: 1,
                isRetrograde: false,
                isCombust: false,
                dignity: .neutral,
                bhava: 1,
                charaKaraka: nil,
                speedDegPerDay: nil
            ),
            planets: GoldenChartFixtures.tagore.planets,
            bhavas: GoldenChartFixtures.tagore.bhavas,
            vargas: GoldenChartFixtures.tagore.vargas,
            shadbala: GoldenChartFixtures.tagore.shadbala,
            ashtakavarga: GoldenChartFixtures.tagore.ashtakavarga,
            dashaNodes: GoldenChartFixtures.tagore.dashaNodes,
            currentDashaVector: "Sun › Venus › Mercury",
            yogas: GoldenChartFixtures.tagore.yogas,
            sarvatobhadra: GoldenChartFixtures.tagore.sarvatobhadra,
            kota: GoldenChartFixtures.tagore.kota,
            notes: notes.isEmpty ? [] : [
                ChartNote(id: UUID(), date: Date(), category: "Initial Intake", content: notes, tags: ["#Intake"])
            ],
            predictions: []
        )

        ChartStore.shared.saveChart(detail: detail)
        onSave?(detail)
        dismiss()
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
