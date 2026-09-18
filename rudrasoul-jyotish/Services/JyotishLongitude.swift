import Foundation

// Shared, pure helpers for sidereal longitudes. Every calculator and view uses
// these so that a sign, nakshatra, or DMS string is derived in exactly one place.

extension Double {
    /// Wraps any angle into 0 ..< 360.
    var normalizedLongitude360: Double {
        let remainder = truncatingRemainder(dividingBy: 360)
        return remainder < 0 ? remainder + 360 : remainder
    }

    /// Degrees inside the sign, 0 ..< 30.
    var longitudeWithinRasi: Double {
        normalizedLongitude360.truncatingRemainder(dividingBy: 30)
    }

    /// Formats the in-sign part of an absolute longitude as `DD° MM' SS"`.
    var dmsStringInRasi: String {
        let totalSeconds = Int((longitudeWithinRasi * 3_600).rounded())
        let clamped = min(totalSeconds, 30 * 3_600 - 1)
        return String(format: "%02d° %02d' %02d\"", clamped / 3_600, (clamped / 60) % 60, clamped % 60)
    }
}

extension Rasi {
    /// The sign containing an absolute sidereal longitude.
    init(absoluteLongitude: Double) {
        let index = Int(absoluteLongitude.normalizedLongitude360 / 30)
        self = Rasi(rawValue: min(index, 11) + 1) ?? .aries
    }

    /// The sign `offset` places ahead (positive) or behind (negative) of this one.
    func advanced(by offset: Int) -> Rasi {
        let index = (((rawValue - 1 + offset) % 12) + 12) % 12
        return Rasi(rawValue: index + 1) ?? self
    }

    /// Count of signs from this sign to `other`, inclusive, counting forward (1 ... 12).
    func count(to other: Rasi) -> Int {
        ((other.rawValue - rawValue + 12) % 12) + 1
    }

    /// Odd signs (Aries, Gemini, …) are male/direct; even signs are female/reverse.
    var isOdd: Bool { rawValue % 2 == 1 }
}

extension Nakshatra {
    /// Span of one of the 27 equal nakshatras, in degrees.
    static let span: Double = 360.0 / 27.0

    /// The 27-fold nakshatra containing an absolute sidereal longitude (Abhijit is never returned).
    init(absoluteLongitude: Double) {
        let index = Int(absoluteLongitude.normalizedLongitude360 / Self.span)
        self = Nakshatra(rawValue: min(index, 26) + 1) ?? .ashwini
    }

    /// The pada (1 ... 4) of an absolute sidereal longitude.
    static func pada(absoluteLongitude: Double) -> Int {
        let withinNakshatra = absoluteLongitude.normalizedLongitude360.truncatingRemainder(dividingBy: span)
        return min(Int(withinNakshatra / (span / 4)), 3) + 1
    }

    /// Fraction of the nakshatra already traversed, 0 ..< 1.
    static func fractionTraversed(absoluteLongitude: Double) -> Double {
        absoluteLongitude.normalizedLongitude360.truncatingRemainder(dividingBy: span) / span
    }
}

extension PlanetPosition {
    /// Absolute sidereal longitude in decimal degrees, 0 ..< 360.
    var absoluteLongitude: Double {
        Double(rasi.rawValue - 1) * 30 + longitudeInRasi
    }
}
