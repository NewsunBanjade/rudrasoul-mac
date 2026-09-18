import EphemerisKit
import Foundation

extension ChartCalculationService {
    /// Sidereal positions of the nine grahas at any instant, for transits (gochara).
    ///
    /// Dignities and combustion are evaluated among the transiting planets themselves.
    /// House numbers are not meaningful here and are returned as 1; views count houses
    /// from the natal Lagna or Moon.
    func transitPositions(
        at date: Date,
        ayanamsa: Ayanamsa?,
        nodeCalculation: ChartCalculationInput.NodeCalculation
    ) async throws -> [PlanetPosition] {
        let positions = try await planetPositions(
            julianDay: JulianDay(date: date),
            settings: EphemerisSettings(source: .swiss, ayanamsa: ayanamsa),
            nodeCalculation: nodeCalculation,
            cusps: []
        )
        return GrahaDignityCalculator.applyingDignities(to: positions)
    }
}
