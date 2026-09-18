import Foundation
import Testing
@testable import rudrasoul_jyotish

@MainActor
struct Nakshatra28Tests {
    @Test func abhijitOccupiesTheEndOfUttaraAshadhaAndStartOfShravana() {
        #expect(Nakshatra28.nakshatra(absoluteLongitude: 276.5) == .uttaraAshadha)
        #expect(Nakshatra28.nakshatra(absoluteLongitude: 277) == .abhijit)
        #expect(Nakshatra28.nakshatra(absoluteLongitude: 281) == .shravana)
        #expect(Nakshatra28.sequence.count == 28)
        #expect(Nakshatra28.count(from: .revati, to: .ashwini) == 2)
        #expect(Nakshatra28.count(from: .uttaraAshadha, to: .shravana) == 3)
    }
}

@MainActor
struct KotaChakraCalculatorTests {
    @Test func zonesFollowTheSevenCellLegs() {
        #expect(KotaChakraCalculator.zone(forSequence: 1) == .bahya)
        #expect(KotaChakraCalculator.zone(forSequence: 4) == .stambha)
        #expect(KotaChakraCalculator.zone(forSequence: 11) == .stambha)
        #expect(KotaChakraCalculator.zone(forSequence: 28) == .bahya)

        let zones = (1...28).map { KotaChakraCalculator.zone(forSequence: $0) }
        #expect(zones.filter { $0 == .stambha }.count == 4)
        #expect(zones.filter { $0 == .madhya }.count == 8)
        #expect(zones.filter { $0 == .prakara }.count == 8)
        #expect(zones.filter { $0 == .bahya }.count == 8)
    }

    @Test func directMotionEntersOnDiagonalsAndRetrogradeReverses() {
        #expect(KotaChakraCalculator.isEntering(sequence: 2, isRetrograde: false))
        #expect(!KotaChakraCalculator.isEntering(sequence: 6, isRetrograde: false))
        #expect(!KotaChakraCalculator.isEntering(sequence: 2, isRetrograde: true))
        #expect(KotaChakraCalculator.isEntering(sequence: 6, isRetrograde: true))
        #expect(KotaChakraCalculator.isEntering(sequence: 4, isRetrograde: false))
    }

    @Test func swamiAndPalaComeFromTheMoon() {
        // Moon at 45°: Taurus 15°, Rohini (40° – 53°20').
        let moon = position(.moon, longitude: 45)
        let sun = position(.sun, longitude: 100) // Pushya, 5th from Rohini → Madhya on the exit leg
        let lagna = position(.ascendant, longitude: 10)
        let kota = KotaChakraCalculator.calculate(planets: [moon, sun], lagna: lagna)

        #expect(kota.kotaSwami == .venus)
        #expect(kota.kotaPala == .moon)
        #expect(kota.janmaNakshatra == .rohini)
        #expect(kota.cells?.count == 28)
        #expect(kota.cells?.first?.nakshatra == .rohini)
        #expect(kota.cells?.first?.grahas == [.moon])
        #expect(kota.praveshaGrahas.contains(.moon))
        #expect(kota.nirgamaGrahas.contains(.sun))
        #expect(kota.zoneAssignments[.madhya]?.contains(.sun) == true)
        #expect(kota.cells?[4].grahas == [.sun])
    }

    private func position(_ graha: Graha, longitude: Double) -> PlanetPosition {
        PlanetPosition(
            graha: graha,
            rasi: Rasi(absoluteLongitude: longitude),
            longitudeInRasi: longitude.longitudeWithinRasi,
            formattedDMS: "",
            nakshatra: Nakshatra(absoluteLongitude: longitude),
            pada: 1,
            isRetrograde: false,
            isCombust: false,
            dignity: .neutral,
            bhava: 1,
            charaKaraka: nil,
            speedDegPerDay: nil
        )
    }
}

@MainActor
struct SarvatobhadraCalculatorTests {
    @Test func layoutHasEightyOneCellsWithTheClassicalPerimeter() {
        let cells = SarvatobhadraCalculator.layout()
        #expect(cells.count == 81)
        #expect(cells.map(\.id) == Array(0..<81))

        let nakshatraCells = cells.filter { $0.nakshatra != nil }
        #expect(nakshatraCells.count == 28)
        #expect(nakshatraCells.allSatisfy { $0.row == 0 || $0.row == 8 || $0.col == 0 || $0.col == 8 })
        #expect(cells.filter { $0.rasi != nil }.count == 12)
        #expect(cells.filter(\.isSpecialSound).count == 16)

        #expect(cell(cells, row: 0, col: 1).nakshatra == .krittika)
        #expect(cell(cells, row: 0, col: 7).nakshatra == .ashlesha)
        #expect(cell(cells, row: 1, col: 8).nakshatra == .magha)
        #expect(cell(cells, row: 8, col: 7).nakshatra == .anuradha)
        #expect(cell(cells, row: 8, col: 2).nakshatra == .abhijit)
        #expect(cell(cells, row: 8, col: 1).nakshatra == .shravana)
        #expect(cell(cells, row: 1, col: 0).nakshatra == .bharani)
        #expect(cell(cells, row: 4, col: 4).label == SarvatobhadraCalculator.centreLabel)
    }

    @Test func planetsLandInTheirNakshatraCellAndCastFrontVedha() {
        // Sun at 30°: Krittika (26°40' – 40°) → top row, column 1.
        let sun = PlanetPosition(
            graha: .sun, rasi: .taurus, longitudeInRasi: 0, formattedDMS: "", nakshatra: .krittika, pada: 2,
            isRetrograde: false, isCombust: false, dignity: .neutral, bhava: 1, charaKaraka: nil, speedDegPerDay: nil
        )
        let lagna = PlanetPosition(
            graha: .ascendant, rasi: .aries, longitudeInRasi: 10, formattedDMS: "", nakshatra: .ashwini, pada: 4,
            isRetrograde: false, isCombust: false, dignity: .neutral, bhava: 1, charaKaraka: nil, speedDegPerDay: nil
        )
        let data = SarvatobhadraCalculator.calculate(planets: [sun], lagna: lagna)

        let sunCell = cell(data.cells, row: 0, col: 1)
        #expect(sunCell.occupyingGrahas == [.sun])
        #expect(cell(data.cells, row: 0, col: 0).occupyingGrahas.isEmpty)
        #expect(data.cells.first { $0.nakshatra == .ashwini }?.occupyingGrahas == [.ascendant])

        let front = SarvatobhadraCalculator.struckCells(from: sunCell, direction: .front, in: data.cells)
        #expect(front.last?.nakshatra == .shravana)
        #expect(front.count == 8)
        #expect(data.vedhaDetails?.contains { $0.graha == .sun && $0.direction == .front && $0.targetLabel == Nakshatra.shravana.name } == true)
        #expect(!data.vedhas.isEmpty)
        #expect(data.vedhaDetails?.allSatisfy { $0.graha == .sun } == true)
    }

    private func cell(_ cells: [SarvatobhadraData.Cell], row: Int, col: Int) -> SarvatobhadraData.Cell {
        cells[row * 9 + col]
    }
}
