import SwiftUI

/// A native macOS transit date control with forward and backward steppers.
struct TransitDateStepper: View {
    @Binding var date: Date
    var onResetToNow: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: DesignSpacing.xSmall) {
            Button("-1Y") { step(by: .year, value: -1) }
                .buttonStyle(.borderless)
                .designTextStyle(.caption, monospacedDigits: true)

            Button("-1M") { step(by: .month, value: -1) }
                .buttonStyle(.borderless)
                .designTextStyle(.caption, monospacedDigits: true)

            Button("-1D") { step(by: .day, value: -1) }
                .buttonStyle(.borderless)
                .designTextStyle(.caption, monospacedDigits: true)

            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .datePickerStyle(.compact)

            Button("+1D") { step(by: .day, value: 1) }
                .buttonStyle(.borderless)
                .designTextStyle(.caption, monospacedDigits: true)

            Button("+1M") { step(by: .month, value: 1) }
                .buttonStyle(.borderless)
                .designTextStyle(.caption, monospacedDigits: true)

            Button("+1Y") { step(by: .year, value: 1) }
                .buttonStyle(.borderless)
                .designTextStyle(.caption, monospacedDigits: true)

            Button("Now") {
                date = Date()
                onResetToNow?()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .designTextStyle(.caption)
        }
        .padding(.horizontal, DesignSpacing.small)
        .padding(.vertical, DesignSpacing.xSmall)
        .background(DesignColor.groupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignColor.separator, lineWidth: 1)
        )
    }

    private func step(by component: Calendar.Component, value: Int) {
        if let newDate = Calendar.current.date(byAdding: component, value: value, to: date) {
            date = newDate
        }
    }
}
