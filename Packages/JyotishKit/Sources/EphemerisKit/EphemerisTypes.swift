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

public enum EphemerisError: Error, Equatable, Sendable {
    case invalidCoordinates
    case calculationFailed(String)
    case bundledEphemerisDataUnavailable
    case missingSwissEphemerisData
    case houseCalculationFailed
}
