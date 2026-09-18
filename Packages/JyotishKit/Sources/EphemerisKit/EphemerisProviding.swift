public protocol EphemerisProviding: Sendable {
    func position(
        of graha: Graha,
        at julianDay: JulianDay,
        settings: EphemerisSettings
    ) async throws -> EclipticPosition

    func houses(
        at julianDay: JulianDay,
        coordinates: GeographicCoordinates,
        system: HouseSystem,
        ayanamsa: Ayanamsa?
    ) async throws -> Houses

    /// The first rising or setting of `graha` strictly after `julianDay`, using the
    /// Hindu convention (centre of the disc on the true horizon, no refraction).
    func riseSetTime(
        of graha: Graha,
        event: RiseSetEvent,
        after julianDay: JulianDay,
        coordinates: GeographicCoordinates,
        source: EphemerisSource
    ) async throws -> JulianDay

    /// The ayanamsa value in degrees at `julianDay` for the given sidereal mode.
    func ayanamsaValue(at julianDay: JulianDay, ayanamsa: Ayanamsa) async -> Double
}
