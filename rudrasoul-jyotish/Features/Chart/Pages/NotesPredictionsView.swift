import SwiftUI

/// Practitioner notes and the prediction journal. Every change is handed back through
/// `onUpdate`, which the workspace uses to persist the chart in the library.
struct NotesPredictionsView: View {
    @State private var chart: ChartDetail
    let onUpdate: ((ChartDetail) -> Void)?

    @State private var newNoteText: String = ""
    @State private var selectedTab: Int = 0 // 0 = Notes, 1 = Predictions
    @State private var isAddingPrediction = false
    @State private var predictionTitle = ""
    @State private var predictionDate = Date()
    @State private var predictionDetails = ""
    @State private var predictionDashaContext = ""

    init(chart: ChartDetail, onUpdate: ((ChartDetail) -> Void)? = nil) {
        _chart = State(initialValue: chart)
        self.onUpdate = onUpdate
    }

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
                    Image(systemName: onUpdate == nil ? "exclamationmark.circle" : "checkmark.circle.fill")
                        .foregroundStyle(onUpdate == nil ? DesignColor.warning : DesignColor.benefic)
                    Text(onUpdate == nil ? "Changes are not saved in this view" : "Saved to the library on every change")
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

    private func persist() {
        onUpdate?(chart)
    }

    // MARK: - Notes

    private var trimmedNote: String {
        newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var notesContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                    Text("Add an observation")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)

                    TextEditor(text: $newNoteText)
                        .font(.body)
                        .frame(height: 80)
                        .border(DesignColor.separator, width: 1)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    HStack {
                        Text("Running: \(chart.currentDashaVector)")
                            .designTextStyle(.caption, monospacedDigits: true)
                            .foregroundStyle(DesignColor.secondaryText)
                        Spacer()
                        Button("Save Note") {
                            saveNote()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(trimmedNote.isEmpty)
                    }
                }
                .padding(DesignSpacing.small)
                .background(DesignColor.groupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                if chart.notes.isEmpty {
                    Text("No notes yet.")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)
                }

                ForEach(chart.notes) { note in
                    noteCard(note)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteNote(note)
                            } label: {
                                Label("Delete Note", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(DesignSpacing.medium)
        }
    }

    private func saveNote() {
        guard !trimmedNote.isEmpty else { return }
        let note = ChartNote(
            id: UUID(),
            date: Date(),
            category: "Observation",
            content: trimmedNote,
            tags: ["#Observation"]
        )
        chart.notes.insert(note, at: 0)
        newNoteText = ""
        persist()
    }

    private func deleteNote(_ note: ChartNote) {
        chart.notes.removeAll { $0.id == note.id }
        persist()
    }

    private func noteCard(_ note: ChartNote) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(note.category)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DesignColor.accent)
                Spacer()
                Text(note.date, format: .dateTime.year().month().day().hour().minute())
                    .designTextStyle(.caption, monospacedDigits: true)
                    .foregroundStyle(DesignColor.secondaryText)
            }

            Text(note.content)
                .designTextStyle(.body)
                .foregroundStyle(DesignColor.primaryText)
                .textSelection(.enabled)

            if !note.tags.isEmpty {
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
        }
        .padding(DesignSpacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignColor.background)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignColor.separator, lineWidth: 1)
        )
    }

    // MARK: - Predictions

    private var trimmedPredictionTitle: String {
        predictionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var predictionsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                HStack {
                    Text("Logged predictions and their outcomes")
                        .designTextStyle(.section)
                    Spacer()
                    Button(isAddingPrediction ? "Cancel" : "Log Prediction…") {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isAddingPrediction.toggle()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                if isAddingPrediction {
                    predictionForm
                }

                if chart.predictions.isEmpty {
                    Text("No predictions logged yet. Record a prediction with its target date, then mark it confirmed or inaccurate once the outcome is known.")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)
                }

                ForEach(chart.predictions) { prediction in
                    predictionCard(prediction)
                }
            }
            .padding(DesignSpacing.medium)
        }
    }

    private var predictionForm: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.small) {
            TextField("Prediction (e.g. change of residence)", text: $predictionTitle)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: DesignSpacing.medium) {
                DatePicker("Target date", selection: $predictionDate, displayedComponents: .date)
                    .datePickerStyle(.field)
                TextField("Dasha context (optional)", text: $predictionDashaContext)
                    .textFieldStyle(.roundedBorder)
            }

            TextEditor(text: $predictionDetails)
                .font(.body)
                .frame(height: 64)
                .border(DesignColor.separator, width: 1)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            HStack {
                Spacer()
                Button("Save Prediction") {
                    savePrediction()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(trimmedPredictionTitle.isEmpty)
            }
        }
        .padding(DesignSpacing.small)
        .background(DesignColor.groupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func savePrediction() {
        guard !trimmedPredictionTitle.isEmpty else { return }
        let context = predictionDashaContext.trimmingCharacters(in: .whitespacesAndNewlines)
        let record = PredictionRecord(
            id: UUID(),
            title: trimmedPredictionTitle,
            targetDate: predictionDate,
            status: .pending,
            dashaContext: context.isEmpty ? chart.currentDashaVector : context,
            details: predictionDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        chart.predictions.insert(record, at: 0)
        predictionTitle = ""
        predictionDetails = ""
        predictionDashaContext = ""
        predictionDate = Date()
        isAddingPrediction = false
        persist()
    }

    private func setStatus(_ status: PredictionRecord.Status, for prediction: PredictionRecord) {
        guard let index = chart.predictions.firstIndex(where: { $0.id == prediction.id }) else { return }
        chart.predictions[index] = PredictionRecord(
            id: prediction.id,
            title: prediction.title,
            targetDate: prediction.targetDate,
            status: status,
            dashaContext: prediction.dashaContext,
            details: prediction.details
        )
        persist()
    }

    private func deletePrediction(_ prediction: PredictionRecord) {
        chart.predictions.removeAll { $0.id == prediction.id }
        persist()
    }

    private func predictionCard(_ prediction: PredictionRecord) -> some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
            HStack {
                Text(prediction.title)
                    .designTextStyle(.section)
                Spacer()
                Menu {
                    ForEach(PredictionRecord.Status.allCases, id: \.self) { status in
                        Button(status.rawValue) {
                            setStatus(status, for: prediction)
                        }
                    }
                    Divider()
                    Button(role: .destructive) {
                        deletePrediction(prediction)
                    } label: {
                        Label("Delete Prediction", systemImage: "trash")
                    }
                } label: {
                    statusBadge(for: prediction.status)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Change the outcome")
            }

            HStack {
                Text("Target: \(prediction.targetDate.formatted(date: .abbreviated, time: .omitted))")
                    .designTextStyle(.caption, monospacedDigits: true)
                Spacer()
                Text("Dasha: \(prediction.dashaContext)")
                    .designTextStyle(.caption, monospacedDigits: true)
                    .foregroundStyle(DesignColor.accent)
            }

            if !prediction.details.isEmpty {
                Text(prediction.details)
                    .designTextStyle(.body)
                    .foregroundStyle(DesignColor.primaryText)
                    .textSelection(.enabled)
            }
        }
        .padding(DesignSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignColor.background)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignColor.separator, lineWidth: 1)
        )
    }

    private func statusBadge(for status: PredictionRecord.Status) -> some View {
        let color: Color = switch status {
        case .confirmed: DesignColor.benefic
        case .pending: DesignColor.accent
        case .inaccurate: DesignColor.malefic
        }

        return Text(status.rawValue)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
