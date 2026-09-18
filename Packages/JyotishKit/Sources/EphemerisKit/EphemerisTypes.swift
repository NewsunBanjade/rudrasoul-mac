import Foundation

public struct JulianDay: Hashable, Sendable {
    public let value: Double

    public init(_ value: Double) {
        self.value = value
    }
}

public enum Graha: Int32, CaseIterable, Sendable {
    case sun = 0
    case moon = 1
    case mercury = 2
    case venus = 3
    case mars = 4
    case jupiter = 5
    case saturn = 6
    case uranus = 7
    case neptune = 8
    case pluto = 9
    case meanNode = 10
    case trueNode = 11
}

public enum EphemerisSource: Sendable {
    case swiss
    case moshier
}

public enum Ayanamsa: Int32, Sendable {
    case lahiri = 1
    case raman = 3
    case krishnamurti = 5
}

public struct EphemerisSettings: Sendable {
    public var source: EphemerisSource
    public var ayanamsa: Ayanamsa?

    public init(source: EphemerisSource = .swiss, ayanamsa: Ayanamsa? = .lahiri) {
        self.source = source
        self.ayanamsa = ayanamsa
    }
}

public struct EclipticPosition: Equatable, Sendable {
    public let longitude: Double
    public let latitude: Double
    public let distanceAU: Double
    public let longitudeSpeed: Double
    public let latitudeSpeed: Double
    public let distanceSpeed: Double
    public let source: EphemerisSource
}

public struct GeographicCoordinates: Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public enum HouseSystem: Int32, Sendable {
    case placidus = 80
    case koch = 75
    case equal = 69
    case wholeSign = 87
}

public struct Houses: Equatable, Sendable {
    public let cusps: [Double]
    public let ascendant: Double
    public let midheaven: Double
    public let vertex: Double
}

/// A horizon event of a body for an observer on the ground.
public enum RiseSetEvent: Sendable {
    case rise
    case set
}

public enum EphemerisError: Error, Equatable, Sendable {
    case invalidCoordinates
    case calculationFailed(String)
    case bundledEphemerisDataUnavailable
    case missingSwissEphemerisData
    case houseCalculationFailed
    /// The body never rises or sets at this latitude around the requested day (polar regions).
    case bodyDoesNotRiseOrSet
}

public extension JulianDay {
    /// Julian Day of 1970-01-01 00:00 UTC, the Unix epoch.
    static let unixEpoch = JulianDay(2_440_587.5)

    /// Converts a Julian Day in Universal Time to a Foundation date.
    var date: Date {
        Date(timeIntervalSince1970: (value - Self.unixEpoch.value) * 86_400)
    }

    /// Creates a Julian Day in Universal Time from a Foundation date.
    init(date: Date) {
        self.init(Self.unixEpoch.value + date.timeIntervalSince1970 / 86_400)
    }
}
