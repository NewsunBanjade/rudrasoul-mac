import EphemerisKit
import Testing

@Suite("Swiss Ephemeris integration", .serialized)
struct SwissEphemerisTests {
    private let ephemeris = SwissEphemeris.shared
    private let j2000 = JulianDay(2_451_545.0)
    private let lahiriMoshier = EphemerisSettings(source: .moshier, ayanamsa: .lahiri)

    @Test("matches the documented J2000 Lahiri reference within one arcsecond")
    func j2000LahiriPositions() async throws {
        let expectedLongitudes: [(Graha, Double)] = [
            (.sun, 256.5156971944),
            (.moon, 199.4705530000),
            (.mercury, 248.0360525278),
            (.venus, 217.7125758333),
            (.mars, 304.1100908333),
            (.jupiter, 1.3998078333),
            (.saturn, 16.5424164722),
            (.meanNode, 101.1874235833),
            (.trueNode, 100.0996729167),
        ]

        for (graha, expectedLongitude) in expectedLongitudes {
            let position = try await ephemeris.position(
                of: graha,
                at: j2000,
                settings: lahiriMoshier
            )
            #expect(abs(position.longitude - expectedLongitude) <= 1.0 / 3_600.0)
            #expect(position.source == .moshier)
        }
    }

    @Test("uses bundled Swiss planetary and lunar data by default")
    func bundledSwissData() async throws {
        let swissLahiri = EphemerisSettings(source: .swiss, ayanamsa: .lahiri)
        let expectedLongitudes: [(Graha, Double)] = [
            (.sun, 256.5156961944),
            (.moon, 199.4705289722),
            (.trueNode, 100.1008003611),
        ]

        for (graha, expectedLongitude) in expectedLongitudes {
            let position = try await ephemeris.position(
                of: graha,
                at: j2000,
                settings: swissLahiri
            )
            #expect(abs(position.longitude - expectedLongitude) <= 1.0 / 3_600.0)
            #expect(position.source == .swiss)
        }
    }

    @Test("calculates sidereal whole-sign houses for Kathmandu")
    func siderealWholeSignHouses() async throws {
        let houses = try await ephemeris.houses(
            at: j2000,
            coordinates: GeographicCoordinates(latitude: 27.7172, longitude: 85.3240),
            system: .wholeSign,
            ayanamsa: .lahiri
        )

        #expect(houses.cusps == [60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 0, 30])
        #expect(abs(houses.ascendant - 83.0001266944) <= 1.0 / 3_600.0)
        #expect(abs(houses.midheaven - 342.4437143056) <= 1.0 / 3_600.0)
        #expect(abs(houses.vertex - 212.4025475278) <= 1.0 / 3_600.0)
    }

    @Test("rejects out-of-range geographic coordinates")
    func invalidCoordinates() async {
        await #expect(throws: EphemerisError.invalidCoordinates) {
            try await ephemeris.houses(
                at: j2000,
                coordinates: GeographicCoordinates(latitude: 91, longitude: 85.3240),
                system: .wholeSign,
                ayanamsa: .lahiri
            )
        }
    }

    @Test("serializes concurrent requests through the ephemeris actor")
    func concurrentRequestsRemainDeterministic() async throws {
        let positions = try await withThrowingTaskGroup(of: EclipticPosition.self) { group in
            for _ in 0 ..< 32 {
                group.addTask {
                    try await ephemeris.position(of: .moon, at: j2000, settings: lahiriMoshier)
                }
            }

            var positions: [EclipticPosition] = []
            for try await position in group {
                positions.append(position)
            }
            return positions
        }

        #expect(positions.count == 32)
        #expect(positions.allSatisfy { abs($0.longitude - 199.4705530000) <= 1.0 / 3_600.0 })
    }
}
