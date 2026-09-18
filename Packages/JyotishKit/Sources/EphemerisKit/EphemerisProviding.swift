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
}
