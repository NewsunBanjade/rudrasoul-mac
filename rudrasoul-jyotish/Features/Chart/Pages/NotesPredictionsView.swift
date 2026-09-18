import SwiftUI

struct NotesPredictionsView: View {
    @State var chart: ChartDetail
    @State private var newNoteText: String = ""
    @State private var selectedTab: Int = 0 // 0 = Notes, 1 = Predictions

    var body: some View {
        VStack(spacing: 0) {
            // Tab switch bar
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("Practitioner Notes").tag(0)
                    Text("Prediction Journal").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignColor.benefic)
                    Text("Autosaved to library")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)
                }
            }
            .padding(.horizontal, DesignSpacing.medium)
            .padding(.vertical, DesignSpacing.small)
            .background(DesignColor.groupedBackground)
            .overlay(alignment: .bottom) { Divider() }

            if selectedTab == 0 {
                notesContent
            } else {
                predictionsContent
            }
        }
        .background(DesignColor.background)
    }

    private var notesContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                // New Note Box
                VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                    Text("Add Clinical Observation")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)

                    TextEditor(text: $newNoteText)
                        .font(.body)
                        .frame(height: 80)
                        .border(DesignColor.separator, width: 1)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    HStack {
                        Spacer()
                        Button("Save Note") {
                            guard !newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                            let note = ChartNote(
                                id: UUID(),
                                date: Date(),
                                category: "Clinical",
                                content: newNoteText,
                                tags: ["#Clinical"]
                            )
                            chart.notes.insert(note, at: 0)
                            newNoteText = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(DesignSpacing.small)
                .background(DesignColor.groupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                // Existing Notes List
                ForEach(chart.notes) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(note.category)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(DesignColor.accent)
                            Spacer()
                            Text(note.date, format: .dateTime.year().month().day().hour().minute())
                                .designTextStyle(.caption, monospacedDigits: true)
                                .foregroundStyle(DesignColor.secondaryText)
                        }

                        Text(note.content)
                            .designTextStyle(.body)
                            .foregroundStyle(DesignColor.primaryText)

                        HStack {
                            ForEach(note.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 9).monospaced())
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(DesignColor.groupedBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                        }
                    }
                    .padding(DesignSpacing.small)
                    .background(DesignColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(DesignColor.separator, lineWidth: 1)
                    )
                }
            }
            .padding(DesignSpacing.medium)
        }
    }

    private var predictionsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                Text("Logged Predictions & Verification Outcomes")
                    .designTextStyle(.section)

                ForEach(chart.predictions) { pred in
                    VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                        HStack {
                            Text(pred.title)
                                .designTextStyle(.section)
                            Spacer()
                            statusBadge(for: pred.status)
                        }

                        HStack {
                            Text("Target Date: \(pred.targetDate.formatted(date: .abbreviated, time: .omitted))")
                                .designTextStyle(.caption, monospacedDigits: true)
                            Spacer()
                            Text("Dasha: \(pred.dashaContext)")
                                .designTextStyle(.caption, monospacedDigits: true)
                                .foregroundStyle(DesignColor.accent)
                        }

                        Text(pred.details)
                            .designTextStyle(.body)
                            .foregroundStyle(DesignColor.primaryText)
                    }
                    .padding(DesignSpacing.medium)
                    .background(DesignColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(DesignColor.separator, lineWidth: 1)
                    )
                }
            }
            .padding(DesignSpacing.medium)
        }
    }

    private func statusBadge(for status: PredictionRecord.Status) -> some View {
        let (color, text) = switch status {
        case .confirmed: (DesignColor.benefic, "Confirmed")
        case .pending: (DesignColor.accent, "Pending")
        case .inaccurate: (DesignColor.malefic, "Inaccurate")
        }

        return Text(text)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
