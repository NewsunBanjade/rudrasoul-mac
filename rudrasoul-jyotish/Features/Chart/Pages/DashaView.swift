import SwiftUI

struct DashaView: View {
    let chart: ChartDetail
    @State private var targetDate: Date = Calendar.current.date(from: DateComponents(year: 1902, month: 4, day: 14))!
    @State private var selectedNode: DashaNode? = nil
    @State private var isDashaInspectorPresented: Bool = true

    var body: some View {
        HSplitView {
            // Main left area: Target date bar, Continuum, and Dasha Hierarchy Table
            VStack(spacing: 0) {
                // Top control bar
                HStack(spacing: DesignSpacing.small) {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Vimshottari · Moon · Solar 365.2422")
                    }
                    .designTextStyle(.caption)
                    .padding(.horizontal, DesignSpacing.small)
                    .padding(.vertical, DesignSpacing.xSmall)
                    .background(DesignColor.groupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    Spacer()

                    Text("Target Date:")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)

                    DatePicker("", selection: $targetDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .datePickerStyle(.compact)

                    Button("Now") {
                        targetDate = Date()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isDashaInspectorPresented.toggle()
                        }
                    } label: {
                        Image(systemName: "sidebar.right")
                            .foregroundStyle(isDashaInspectorPresented ? DesignColor.accent : DesignColor.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .help(isDashaInspectorPresented ? "Hide Dasha Inspector" : "Show Dasha Inspector")
                }
                .padding(.horizontal, DesignSpacing.medium)
                .padding(.vertical, DesignSpacing.small)
                .background(DesignColor.groupedBackground)
                .overlay(alignment: .bottom) { Divider() }

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                        // Lifespan Mahadasha Continuum Strip
                        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                            HStack {
                                Text("Lifespan Mahadasha Continuum (120y Cycle)")
                                    .designTextStyle(.section)
                                Spacer()
                                Text("Active: \(chart.currentDashaVector)")
                                    .designTextStyle(.caption, monospacedDigits: true)
                                    .foregroundStyle(DesignColor.accent)
                            }

                            HStack(spacing: 2) {
                                ForEach(chart.dashaNodes) { node in
                                    VStack(spacing: 2) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(node.statusText == "Focused" ? DesignColor.accent : DesignColor.groupedBackground)
                                            .frame(height: 28)
                                            .overlay(
                                                Text("\(node.lord.shortAbbreviation) \(node.formattedDuration.prefix(3))")
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundColor(node.statusText == "Focused" ? .white : DesignColor.primaryText)
                                            )
                                        Text(node.startDate, format: .dateTime.year())
                                            .font(.system(size: 9).monospaced())
                                            .foregroundColor(DesignColor.secondaryText)
                                    }
                                    .frame(maxWidth: .infinity)
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

                        // Hierarchy Table
                        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                            Text("Vimshottari Hierarchy (MD › AD › PD › SD › PrD)")
                                .designTextStyle(.section)

                            VStack(spacing: 0) {
                                // Table Header
                                HStack {
                                    Text("Lord / Level").frame(width: 150, alignment: .leading)
                                    Text("Start Date").frame(width: 80, alignment: .trailing)
                                    Text("End Date").frame(width: 80, alignment: .trailing)
                                    Text("Duration").frame(width: 65, alignment: .trailing)
                                    Text("Age").frame(width: 45, alignment: .trailing)
                                    Text("Status").frame(width: 65, alignment: .leading).padding(.leading, 6)
                                    Text("Role").frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                                .padding(.horizontal, DesignSpacing.small)
                                .padding(.vertical, DesignSpacing.xSmall)
                                .background(DesignColor.groupedBackground)

                                Divider()

                                // Rows
                                ForEach(chart.dashaNodes) { node in
                                    DashaRow(node: node, indent: 0, isSelected: selectedNode?.id == node.id) {
                                        selectedNode = node
                                    }

                                    ForEach(node.children) { adNode in
                                        DashaRow(node: adNode, indent: 16, isSelected: selectedNode?.id == adNode.id) {
                                            selectedNode = adNode
                                        }

                                        ForEach(adNode.children) { pdNode in
                                            DashaRow(node: pdNode, indent: 32, isSelected: selectedNode?.id == pdNode.id) {
                                                selectedNode = pdNode
                                            }
                                        }
                                    }
                                }
                            }
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
            .frame(minWidth: 320, maxWidth: .infinity)

            // Right side: Dasha Inspector Panel (collapsible)
            if isDashaInspectorPresented {
                VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                    HStack {
                        Text("Dasha Inspector")
                            .designTextStyle(.section)
                        Spacer()
                        Text("Focused")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(DesignColor.accent.opacity(0.15))
                            .foregroundStyle(DesignColor.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }

                    let displayLord = selectedNode?.lord ?? .jupiter
                    HStack(spacing: DesignSpacing.small) {
                        Text(displayLord.astronomicalGlyph)
                            .font(.system(size: 24, weight: .bold))
                            .frame(width: 36, height: 36)
                            .background(DesignColor.groupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(displayLord.sanskritName) (\(displayLord.rawValue))")
                                .designTextStyle(.section)
                            Text("Active Period in Current Focus")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: DesignSpacing.small) {
                        Text("Compound Maitri (Pancha-da)")
                            .designTextStyle(.caption)
                            .foregroundStyle(DesignColor.secondaryText)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Natural").font(.caption2).foregroundColor(DesignColor.secondaryText)
                                Text("Friend").font(.caption.weight(.medium))
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Temporal").font(.caption2).foregroundColor(DesignColor.secondaryText)
                                Text("Mitra").font(.caption.weight(.medium))
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Compound").font(.caption2).foregroundColor(DesignColor.secondaryText)
                                Text("Adhi Mitra").font(.caption.weight(.bold)).foregroundColor(DesignColor.accent)
                            }
                        }
                        .padding(DesignSpacing.small)
                        .background(DesignColor.groupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                        Text("Predictive Indications")
                            .designTextStyle(.caption)
                            .foregroundStyle(DesignColor.secondaryText)
                        Text("Exalted lord active in auspicious house, conferring creative brilliance, philosophical honors, and widespread public respect.")
                            .designTextStyle(.body)
                            .foregroundStyle(DesignColor.primaryText)
                    }

                    Spacer()
                }
                .padding(DesignSpacing.medium)
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 300)
                .background(DesignColor.background)
            }
        }
    }
}

private struct DashaRow: View {
    let node: DashaNode
    let indent: CGFloat
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                HStack(spacing: 4) {
                    if indent > 0 {
                        Spacer().frame(width: indent)
                    }
                    Text(node.lord.astronomicalGlyph)
                    Text(node.lord.sanskritName)
                        .fontWeight(node.level == .mahadasha ? .bold : .medium)
                    Text(node.level.rawValue)
                        .font(.system(size: 9).monospaced())
                        .foregroundColor(DesignColor.secondaryText)
                }
                .frame(width: 150, alignment: .leading)

                Text(node.startDate, format: .dateTime.year().month().day())
                    .frame(width: 80, alignment: .trailing)
                    .designTextStyle(.caption, monospacedDigits: true)

                Text(node.endDate, format: .dateTime.year().month().day())
                    .frame(width: 80, alignment: .trailing)
                    .designTextStyle(.caption, monospacedDigits: true)

                Text(node.formattedDuration)
                    .frame(width: 65, alignment: .trailing)
                    .designTextStyle(.caption, monospacedDigits: true)

                Text(String(format: "%.1f", node.ageAtStart))
                    .frame(width: 45, alignment: .trailing)
                    .designTextStyle(.caption, monospacedDigits: true)

                Text(node.statusText)
                    .frame(width: 65, alignment: .leading)
                    .padding(.leading, 6)
                    .designTextStyle(.caption)
                    .foregroundColor(node.statusText == "Active" || node.statusText == "Focused" ? DesignColor.accent : DesignColor.secondaryText)

                Text(node.role)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, DesignSpacing.small)
            .padding(.vertical, 6)
            .background(isSelected ? DesignColor.accent.opacity(0.12) : (node.statusText == "Focused" ? DesignColor.accent.opacity(0.04) : Color.clear))
        }
        .buttonStyle(.plain)
    }
}
