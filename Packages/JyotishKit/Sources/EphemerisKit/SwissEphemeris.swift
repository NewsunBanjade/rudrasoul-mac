import CSwissEph
import Foundation

/// Serializes all calls into Swiss Ephemeris, whose C runtime owns global mutable state.
public actor SwissEphemeris: EphemerisProviding {
    public static let shared = SwissEphemeris()

    private enum Flag {
        static let swiss: Int32 = 2
        static let moshier: Int32 = 4
        static let speed: Int32 = 256
        static let sidereal: Int32 = 65_536
    }

    private enum RiseFlag {
        static let rise: Int32 = 1
        static let set: Int32 = 2
        /// SE_BIT_HINDU_RISING: disc centre, no refraction, geocentric, no ecliptic latitude.
        static let hinduRising: Int32 = 256 | 512 | 128
    }

    private init() {
        if let dataDirectory = Self.bundledEphemerisDataDirectory() {
            dataDirectory.path.withCString(jp_swe_set_ephemeris_path)
        }
    }

    /// Configures bundled Swiss data for dates from 1800 through 2399.
    /// The data must be present before requesting `.swiss` positions.
    public func configureBundledEphemerisData() {
        guard let dataDirectory = Self.bundledEphemerisDataDirectory() else {
            return
        }
        configure(ephemerisPath: dataDirectory)
    }

    public func configure(ephemerisPath: URL) {
        ephemerisPath.path.withCString(jp_swe_set_ephemeris_path)
    }

    public func julianDay(
        year: Int32,
        month: Int32,
        day: Int32,
        utcHour: Double,
        gregorian: Bool = true
    ) -> JulianDay {
        JulianDay(jp_swe_julian_day(year, month, day, utcHour, gregorian ? 1 : 0))
    }

    public func position(
        of graha: Graha,
        at julianDay: JulianDay,
        settings: EphemerisSettings
    ) throws -> EclipticPosition {
        if let ayanamsa = settings.ayanamsa {
            jp_swe_set_sidereal_mode(ayanamsa.rawValue)
        }

        let requestedSource = sourceFlag(for: settings.source)
        var flags = requestedSource | Flag.speed
        if settings.ayanamsa != nil {
            flags |= Flag.sidereal
        }

        var result = jp_swe_position_result()
        var error = [CChar](repeating: 0, count: 256)
        let returnedFlags = error.withUnsafeMutableBufferPointer { buffer in
            jp_swe_calculate_ut(
                julianDay.value,
                graha.rawValue,
                flags,
                &result,
                buffer.baseAddress,
                buffer.count
            )
        }

        guard returnedFlags >= 0 else {
            let message = String(
                decoding: error.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) },
                as: UTF8.self
            )
            throw EphemerisError.calculationFailed(message)
        }
        guard settings.source != .swiss || returnedFlags & Flag.swiss != 0 else {
            throw EphemerisError.missingSwissEphemerisData
        }

        return EclipticPosition(
            longitude: result.values.0,
            latitude: result.values.1,
            distanceAU: result.values.2,
            longitudeSpeed: result.values.3,
            latitudeSpeed: result.values.4,
            distanceSpeed: result.values.5,
            source: settings.source
        )
    }

    public func houses(
        at julianDay: JulianDay,
        coordinates: GeographicCoordinates,
        system: HouseSystem,
        ayanamsa: Ayanamsa?
    ) throws -> Houses {
        guard (-90 ... 90).contains(coordinates.latitude),
              (-180 ... 180).contains(coordinates.longitude)
        else {
            throw EphemerisError.invalidCoordinates
        }

        if let ayanamsa {
            jp_swe_set_sidereal_mode(ayanamsa.rawValue)
        }
        var result = jp_swe_houses_result()
        let returnCode = jp_swe_houses_ut(
            julianDay.value,
            ayanamsa == nil ? 0 : Flag.sidereal,
            coordinates.latitude,
            coordinates.longitude,
            system.rawValue,
            &result
        )
        guard returnCode == 0 else {
            throw EphemerisError.houseCalculationFailed
        }

        let cusps = withUnsafeBytes(of: result.cusps) { bytes in
            Array(bytes.bindMemory(to: Double.self).dropFirst().prefix(12))
        }
        return Houses(
            cusps: cusps,
            ascendant: result.angles.0,
            midheaven: result.angles.1,
            vertex: result.angles.3
        )
    }

    public func riseSetTime(
        of graha: Graha,
        event: RiseSetEvent,
        after julianDay: JulianDay,
        coordinates: GeographicCoordinates,
        source: EphemerisSource = .swiss
    ) throws -> JulianDay {
        guard (-90 ... 90).contains(coordinates.latitude),
              (-180 ... 180).contains(coordinates.longitude)
        else {
            throw EphemerisError.invalidCoordinates
        }

        let rsmi = (event == .rise ? RiseFlag.rise : RiseFlag.set) | RiseFlag.hinduRising
        var eventJulianDay = 0.0
        var error = [CChar](repeating: 0, count: 256)
        let code = error.withUnsafeMutableBufferPointer { buffer in
            jp_swe_rise_trans(
                julianDay.value,
                graha.rawValue,
                sourceFlag(for: source),
                rsmi,
                coordinates.latitude,
                coordinates.longitude,
                &eventJulianDay,
                buffer.baseAddress,
                buffer.count
            )
        }

        if code == -2 {
            throw EphemerisError.bodyDoesNotRiseOrSet
        }
        guard code >= 0 else {
            let message = String(
                decoding: error.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) },
                as: UTF8.self
            )
            throw EphemerisError.calculationFailed(message)
        }
        return JulianDay(eventJulianDay)
    }

    public func ayanamsaValue(at julianDay: JulianDay, ayanamsa: Ayanamsa) -> Double {
        jp_swe_set_sidereal_mode(ayanamsa.rawValue)
        return jp_swe_get_ayanamsa_ut(julianDay.value)
    }

    private func sourceFlag(for source: EphemerisSource) -> Int32 {
        switch source {
        case .swiss: Flag.swiss
        case .moshier: Flag.moshier
        }
    }

    private nonisolated static func bundledEphemerisDataDirectory() -> URL? {
        Bundle.module.url(forResource: "ephe", withExtension: nil)
    }
}
