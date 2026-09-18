import EphemerisKit
import Foundation

// Rebuilding the calculation input from a stored chart, so that any chart can be
// recalculated with the current engine (new strengths, upagrahas, dashas, ...).

extension ChartCalculationInput {
    /// The input that reproduces `detail` from its stored birth data. Charts saved before the
    /// offset and house system were stored fall back to the time-zone text and whole-sign houses.
    init(recomputing detail: ChartDetail) {
        self.init(
            id: detail.id,
            name: detail.name,
            gender: detail.gender,
            birthDate: detail.birthDate,
            birthTimeString: detail.birthTimeString,
            calendarSystem: detail.calendarSystem,
            bikramSambatDateString: detail.bikramSambatDateString,
            locationName: detail.locationName,
            latitude: detail.latitude,
            longitude: detail.longitude,
            timezoneString: detail.timezoneString,
            utcOffsetSeconds: detail.resolvedUTCOffsetSeconds,
            ayanamsaName: detail.ayanamsaName,
            ayanamsa: detail.ephemerisAyanamsa,
            nodeCalculation: detail.ephemerisNodeCalculation,
            houseSystem: HouseSystem(displayName: detail.houseSystemName ?? "") ?? .wholeSign,
            notes: detail.notes
        )
    }

    /// The signed offset in a time-zone description such as "NST (Nepal) UTC+05:45" or
    /// "LMT (Calcutta Mean Time) UTC+05:53:28"; nil when no "UTC±HH:MM" is present.
    static func utcOffset(inTimezoneString text: String) -> TimeInterval? {
        guard let range = text.range(of: "UTC") else { return nil }
        let rest = text[range.upperBound...].trimmingCharacters(in: .whitespaces)
        guard let signCharacter = rest.first, signCharacter == "+" || signCharacter == "-" else { return nil }
        let digits = rest.dropFirst().prefix { $0.isNumber || $0 == ":" }
        let parts = digits.split(separator: ":").compactMap { Double($0) }
        guard let hours = parts.first else { return nil }
        let minutes = parts.count > 1 ? parts[1] : 0
        let seconds = parts.count > 2 ? parts[2] : 0
        let total = hours * 3_600 + minutes * 60 + seconds
        return signCharacter == "-" ? -total : total
    }
}

extension ChartDetail {
    /// The ephemeris ayanamsa matching the stored ayanamsa name (Lahiri when unrecognised).
    var ephemerisAyanamsa: Ayanamsa {
        let name = ayanamsaName.lowercased()
        if name.contains("raman") { return .raman }
        if name.contains("krishnamurti") || name.contains("kp") { return .krishnamurti }
        return .lahiri
    }

    var ephemerisNodeCalculation: ChartCalculationInput.NodeCalculation {
        nodeCalculation.lowercased().contains("mean") ? .meanNode : .trueNode
    }

    /// The stored offset; otherwise the "UTC±HH:MM" in the time-zone text; otherwise local
    /// mean time from the longitude when the text mentions LMT; otherwise zero.
    var resolvedUTCOffsetSeconds: TimeInterval {
        if let utcOffsetSeconds {
            return utcOffsetSeconds
        }
        if let parsed = ChartCalculationInput.utcOffset(inTimezoneString: timezoneString) {
            return parsed
        }
        if timezoneString.uppercased().contains("LMT"), let degrees = try? longitude.decimalDegrees {
            return degrees * 240
        }
        return 0
    }
}
