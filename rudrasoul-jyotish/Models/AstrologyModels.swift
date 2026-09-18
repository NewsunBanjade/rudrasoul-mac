import Foundation

// MARK: - Graha (Planets)

enum Graha: String, CaseIterable, Identifiable, Sendable, Codable {
    case ascendant = "Lagna"
    case sun = "Sun"
    case moon = "Moon"
    case mars = "Mars"
    case mercury = "Mercury"
    case jupiter = "Jupiter"
    case venus = "Venus"
    case saturn = "Saturn"
    case rahu = "Rahu"
    case ketu = "Ketu"

    var id: String { rawValue }

    var sanskritName: String {
        switch self {
        case .ascendant: "Lagna"
        case .sun: "Surya"
        case .moon: "Chandra"
        case .mars: "Mangala"
        case .mercury: "Budha"
        case .jupiter: "Guru"
        case .venus: "Shukra"
        case .saturn: "Shani"
        case .rahu: "Rahu"
        case .ketu: "Ketu"
        }
    }

    var shortAbbreviation: String {
        switch self {
        case .ascendant: "As"
        case .sun: "Su"
        case .moon: "Mo"
        case .mars: "Ma"
        case .mercury: "Me"
        case .jupiter: "Ju"
        case .venus: "Ve"
        case .saturn: "Sa"
        case .rahu: "Ra"
        case .ketu: "Ke"
        }
    }

    var astronomicalGlyph: String {
        switch self {
        case .ascendant: "Asc"
        case .sun: "☉"
        case .moon: "☽"
        case .mars: "♂"
        case .mercury: "☿"
        case .jupiter: "♃"
        case .venus: "♀"
        case .saturn: "♄"
        case .rahu: "☊"
        case .ketu: "☋"
        }
    }

    var isNaturalBenefic: Bool {
        switch self {
        case .jupiter, .venus, .moon, .mercury: true
        default: false
        }
    }

    var vimshottariYears: Int {
        switch self {
        case .ketu: 7
        case .venus: 20
        case .sun: 6
        case .moon: 10
        case .mars: 7
        case .rahu: 18
        case .jupiter: 16
        case .saturn: 19
        case .mercury: 17
        case .ascendant: 0
        }
    }
}

// MARK: - Rasi (Zodiac Signs)

enum Rasi: Int, CaseIterable, Identifiable, Sendable, Codable {
    case aries = 1
    case taurus = 2
    case gemini = 3
    case cancer = 4
    case leo = 5
    case virgo = 6
    case libra = 7
    case scorpio = 8
    case sagittarius = 9
    case capricorn = 10
    case aquarius = 11
    case pisces = 12

    var id: Int { rawValue }

    var englishName: String {
        switch self {
        case .aries: "Aries"
        case .taurus: "Taurus"
        case .gemini: "Gemini"
        case .cancer: "Cancer"
        case .leo: "Leo"
        case .virgo: "Virgo"
        case .libra: "Libra"
        case .scorpio: "Scorpio"
        case .sagittarius: "Sagittarius"
        case .capricorn: "Capricorn"
        case .aquarius: "Aquarius"
        case .pisces: "Pisces"
        }
    }

    var sanskritName: String {
        switch self {
        case .aries: "Mesha"
        case .taurus: "Vrishabha"
        case .gemini: "Mithuna"
        case .cancer: "Karka"
        case .leo: "Simha"
        case .virgo: "Kanya"
        case .libra: "Tula"
        case .scorpio: "Vrishchika"
        case .sagittarius: "Dhanu"
        case .capricorn: "Makara"
        case .aquarius: "Kumbha"
        case .pisces: "Meena"
        }
    }

    var lord: Graha {
        switch self {
        case .aries, .scorpio: .mars
        case .taurus, .libra: .venus
        case .gemini, .virgo: .mercury
        case .cancer: .moon
        case .leo: .sun
        case .sagittarius, .pisces: .jupiter
        case .capricorn, .aquarius: .saturn
        }
    }

    var element: String {
        switch rawValue % 4 {
        case 1: "Fire"
        case 2: "Earth"
        case 3: "Air"
        default: "Water"
        }
    }
}

// MARK: - Nakshatra (Lunar Mansions)

enum Nakshatra: Int, CaseIterable, Identifiable, Sendable, Codable {
    case ashwini = 1, bharani, krittika, rohini, mrigashira, ardra, punarvasu, pushya, ashlesha
    case magha, purvaPhalguni, uttaraPhalguni, hasta, chitra, swati, vishakha, anuradha, jyeshtha
    case mula, purvaAshadha, uttaraAshadha, shravana, dhanishta, shatabhisha, purvaBhadrapada, uttaraBhadrapada, revati
    case abhijit = 28

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .ashwini: "Ashwini"
        case .bharani: "Bharani"
        case .krittika: "Krittika"
        case .rohini: "Rohini"
        case .mrigashira: "Mrigashira"
        case .ardra: "Ardra"
        case .punarvasu: "Punarvasu"
        case .pushya: "Pushya"
        case .ashlesha: "Ashlesha"
        case .magha: "Magha"
        case .purvaPhalguni: "Purva Phalguni"
        case .uttaraPhalguni: "Uttara Phalguni"
        case .hasta: "Hasta"
        case .chitra: "Chitra"
        case .swati: "Swati"
        case .vishakha: "Vishakha"
        case .anuradha: "Anuradha"
        case .jyeshtha: "Jyeshtha"
        case .mula: "Mula"
        case .purvaAshadha: "Purva Ashadha"
        case .uttaraAshadha: "Uttara Ashadha"
        case .shravana: "Shravana"
        case .dhanishta: "Dhanishta"
        case .shatabhisha: "Shatabhisha"
        case .purvaBhadrapada: "Purva Bhadrapada"
        case .uttaraBhadrapada: "Uttara Bhadrapada"
        case .revati: "Revati"
        case .abhijit: "Abhijit"
        }
    }

    var lord: Graha {
        switch self {
        case .ashwini, .magha, .mula: .ketu
        case .bharani, .purvaPhalguni, .purvaAshadha: .venus
        case .krittika, .uttaraPhalguni, .uttaraAshadha: .sun
        case .rohini, .hasta, .shravana: .moon
        case .mrigashira, .chitra, .dhanishta: .mars
        case .ardra, .swati, .shatabhisha: .rahu
        case .punarvasu, .vishakha, .purvaBhadrapada: .jupiter
        case .pushya, .anuradha, .uttaraBhadrapada: .saturn
        case .ashlesha, .jyeshtha, .revati: .mercury
        case .abhijit: .sun
        }
    }

    var deity: String {
        switch self {
        case .ashwini: "Ashwini Kumaras"
        case .bharani: "Yama"
        case .krittika: "Agni"
        case .rohini: "Brahma / Prajapati"
        case .mrigashira: "Soma"
        case .ardra: "Rudra"
        case .punarvasu: "Aditi"
        case .pushya: "Brihaspati"
        case .ashlesha: "Sarpa"
        case .magha: "Pitris"
        case .purvaPhalguni: "Bhaga"
        case .uttaraPhalguni: "Aryaman"
        case .hasta: "Savitr"
        case .chitra: "Tvashtr"
        case .swati: "Vayu"
        case .vishakha: "Indragni"
        case .anuradha: "Mitra"
        case .jyeshtha: "Indra"
        case .mula: "Nirriti"
        case .purvaAshadha: "Apas"
        case .uttaraAshadha: "Vishvadevas"
        case .shravana: "Vishnu"
        case .dhanishta: "Ashta Vasus"
        case .shatabhisha: "Varuna"
        case .purvaBhadrapada: "Aja Ekapada"
        case .uttaraBhadrapada: "Ahirbudhnya"
        case .revati: "Pushan"
        case .abhijit: "Brahma"
        }
    }

    var gana: String {
        switch self {
        case .ashwini, .mrigashira, .punarvasu, .pushya, .hasta, .swati, .anuradha, .shravana, .revati: "Deva"
        case .bharani, .rohini, .ardra, .purvaPhalguni, .uttaraPhalguni, .purvaAshadha, .uttaraAshadha, .purvaBhadrapada, .uttaraBhadrapada: "Manushya"
        default: "Rakshasa"
        }
    }
}

// MARK: - Dignity & Karakas

enum Dignity: String, Sendable, Codable {
    case exalted = "Exalted"
    case moolatrikona = "Moolatrikona"
    case ownSign = "Own sign"
    case greatFriend = "Adhi Mitra"
    case friend = "Friend"
    case neutral = "Neutral"
    case enemy = "Enemy"
    case greatEnemy = "Adhi Shatru"
    case debilitated = "Debilitated"

    var glyph: String {
        switch self {
        case .exalted: "↑"
        case .debilitated: "↓"
        case .ownSign, .moolatrikona: "★"
        default: ""
        }
    }
}

enum CharaKaraka: String, Sendable, Codable {
    case atmakaraka = "AK"
    case amatyakaraka = "AmK"
    case bhratrukaraka = "BK"
    case matrukaraka = "MK"
    case putrakaraka = "PK"
    case gnatikaraka = "GK"
    case darakaraka = "DK"

    var title: String {
        switch self {
        case .atmakaraka: "Atmakaraka (Soul)"
        case .amatyakaraka: "Amatyakaraka (Career)"
        case .bhratrukaraka: "Bhratrukaraka (Siblings/Guru)"
        case .matrukaraka: "Matrukaraka (Mother/Nurture)"
        case .putrakaraka: "Putrakaraka (Children/Intelligence)"
        case .gnatikaraka: "Gnatikaraka (Obstacles/Kinsmen)"
        case .darakaraka: "Darakaraka (Spouse/Partnership)"
        }
    }
}

// MARK: - PlanetPosition

struct PlanetPosition: Identifiable, Hashable, Sendable, Codable {
    var id: String { graha.rawValue }
    let graha: Graha
    let rasi: Rasi
    let longitudeInRasi: Double
    let formattedDMS: String
    let nakshatra: Nakshatra
    let pada: Int
    let isRetrograde: Bool
    let isCombust: Bool
    let dignity: Dignity
    let bhava: Int
    let charaKaraka: CharaKaraka?
    let speedDegPerDay: Double?

    var displayLabel: String {
        var text = "\(graha.shortAbbreviation)"
        if isRetrograde {
            text += "(R)"
        }
        text += " \(formattedDMS)"
        if !dignity.glyph.isEmpty {
            text += " \(dignity.glyph)"
        }
        return text
    }
}

// MARK: - BhavaData

struct BhavaData: Identifiable, Hashable, Sendable, Codable {
    var id: Int { number }
    let number: Int
    let rasi: Rasi
    let cuspLongitudeDMS: String
    let lord: Graha
    let occupantGrahas: [Graha]
    let name: String
    let significance: String
}

// MARK: - Divisional Charts (Vargas)

enum VargaDivision: String, CaseIterable, Identifiable, Sendable, Codable {
    case d1 = "D-1"
    case d2 = "D-2"
    case d3 = "D-3"
    case d4 = "D-4"
    case d7 = "D-7"
    case d9 = "D-9"
    case d10 = "D-10"
    case d12 = "D-12"
    case d16 = "D-16"
    case d20 = "D-20"
    case d24 = "D-24"
    case d27 = "D-27"
    case d30 = "D-30"
    case d40 = "D-40"
    case d45 = "D-45"
    case d60 = "D-60"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .d1: "Rasi (D-1)"
        case .d2: "Hora (D-2)"
        case .d3: "Drekkana (D-3)"
        case .d4: "Chaturthamsha (D-4)"
        case .d7: "Saptamsha (D-7)"
        case .d9: "Navamsha (D-9)"
        case .d10: "Dasamsha (D-10)"
        case .d12: "Dwadasamsha (D-12)"
        case .d16: "Shodashamsha (D-16)"
        case .d20: "Vimshamsha (D-20)"
        case .d24: "Chaturvimshamsha (D-24)"
        case .d27: "Saptavimshamsha (D-27)"
        case .d30: "Trishamsha (D-30)"
        case .d40: "Khavedamsha (D-40)"
        case .d45: "Akshavedamsha (D-45)"
        case .d60: "Shastiamsha (D-60)"
        }
    }

    var domain: String {
        switch self {
        case .d1: "Physical body and general life path"
        case .d2: "Wealth and assets"
        case .d3: "Siblings and vitality"
        case .d4: "Fixed assets, home, and fortune"
        case .d7: "Children and creative legacy"
        case .d9: "Spouse, dharma, and soul's destiny"
        case .d10: "Profession, authority, and public status"
        case .d12: "Parents and ancestral lineage"
        case .d16: "Vehicles, conveyances, and general happiness"
        case .d20: "Spiritual practice and upasana"
        case .d24: "Learning, higher education, and wisdom"
        case .d27: "Physical strengths and constitutional weaknesses"
        case .d30: "Misfortunes, evils, and sub-conscious patterns"
        case .d40: "Maternal karma and auspicious results"
        case .d45: "Paternal karma and all general indications"
        case .d60: "Past life karma and root causation"
        }
    }
}

struct VargaChart: Identifiable, Hashable, Sendable, Codable {
    var id: String { division.rawValue }
    let division: VargaDivision
    let lagnaRasi: Rasi
    let planetRasis: [Graha: Rasi]
    /// Gulika and Maandi placed in this division. Nil for charts computed before upagrahas existed.
    var upagrahaRasis: [UpagrahaKind: Rasi]? = nil
    /// Shashtiamsa deity of the lagna. Only populated for D-60.
    var lagnaAmsaDetail: ShashtiamsaDetail? = nil
    /// Shashtiamsa deity of each planet. Only populated for D-60.
    var planetAmsaDetails: [Graha: ShashtiamsaDetail]? = nil
}

// MARK: - Shadbala Breakdown

struct ShadbalaBreakdown: Identifiable, Hashable, Sendable, Codable {
    var id: String { graha.rawValue }
    let graha: Graha
    let sthanaBala: Double
    let dikBala: Double
    let kalaBala: Double
    let cheshtaBala: Double
    let naisargikaBala: Double
    let drikBala: Double
    let totalVirupas: Double
    let totalRupas: Double
    let requiredRupas: Double
    let rank: Int

    var percentageOfRequired: Double {
        guard requiredRupas > 0 else { return 0 }
        return (totalRupas / requiredRupas) * 100.0
    }

    var isSufficient: Bool {
        totalRupas >= requiredRupas
    }
}

// MARK: - Ashtakavarga

struct AshtakavargaData: Hashable, Sendable, Codable {
    let sarvashtakavarga: [Rasi: Int]
    let bhinnashtakavarga: [Graha: [Rasi: Int]]

    var totalBindus: Int {
        sarvashtakavarga.values.reduce(0, +)
    }
}

// MARK: - Vimshottari Dasha Hierarchy

enum DashaLevel: String, Sendable, Codable {
    case mahadasha = "MD"
    case antardasha = "AD"
    case pratyantardasha = "PD"
    case sookshma = "SD"
    case prana = "PrD"
}

struct DashaNode: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    let level: DashaLevel
    let lord: Graha
    let startDate: Date
    let endDate: Date
    let formattedDuration: String
    let ageAtStart: Double
    let statusText: String
    let role: String
    var children: [DashaNode]

    init(
        id: UUID = UUID(),
        level: DashaLevel,
        lord: Graha,
        startDate: Date,
        endDate: Date,
        formattedDuration: String,
        ageAtStart: Double,
        statusText: String,
        role: String,
        children: [DashaNode] = []
    ) {
        self.id = id
        self.level = level
        self.lord = lord
        self.startDate = startDate
        self.endDate = endDate
        self.formattedDuration = formattedDuration
        self.ageAtStart = ageAtStart
        self.statusText = statusText
        self.role = role
        self.children = children
    }
}

// MARK: - Yogas and Doshas

struct YogaRecord: Identifiable, Hashable, Sendable, Codable {
    var id: String { name }
    let name: String
    let category: String
    let participatingGrahas: [Graha]
    let description: String
    let referenceSource: String
    let isAuspicious: Bool
    let cancellationNote: String?
}

// MARK: - Chakras (Sarvatobhadra & Kota)

struct SarvatobhadraData: Hashable, Sendable, Codable {
    struct Cell: Identifiable, Hashable, Sendable, Codable {
        let id: Int
        let row: Int
        let col: Int
        let label: String
        let nakshatra: Nakshatra?
        let rasi: Rasi?
        let occupyingGrahas: [Graha]
        let isSpecialSound: Bool
    }

    let cells: [Cell]
    let vedhas: [String]
    /// Structured vedha records; nil for charts computed before the SBC calculator existed.
    var vedhaDetails: [SarvatobhadraVedha]? = nil
}

struct KotaChakraData: Hashable, Sendable, Codable {
    enum Zone: String, CaseIterable, Identifiable, Sendable, Codable {
        case stambha = "Stambha (Pillar / Core)"
        case madhya = "Madhya (Inner Hall)"
        case prakara = "Prakara (Outer Wall)"
        case bahya = "Bahya (Outside Field)"

        var id: String { rawValue }
    }

    let kotaSwami: Graha
    let kotaPala: Graha
    let zoneAssignments: [Zone: [Graha]]
    let praveshaGrahas: [Graha]
    let nirgamaGrahas: [Graha]
    /// The Janma (birth Moon) nakshatra the chakra is counted from; nil for legacy data.
    var janmaNakshatra: Nakshatra? = nil
    /// All 28 cells in sequence from the Janma nakshatra; nil for legacy data.
    var cells: [KotaCell]? = nil
}

// MARK: - Notes & Predictions

struct ChartNote: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    let date: Date
    let category: String
    var content: String
    let tags: [String]
}

struct PredictionRecord: Identifiable, Hashable, Sendable, Codable {
    enum Status: String, CaseIterable, Sendable, Codable {
        case pending = "Pending"
        case confirmed = "Confirmed"
        case inaccurate = "Inaccurate"
    }

    let id: UUID
    let title: String
    let targetDate: Date
    let status: Status
    let dashaContext: String
    let details: String
}

// MARK: - Comprehensive Chart Detail

struct ChartDetail: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    let name: String
    let gender: String
    let birthDate: Date
    let birthTimeString: String
    let calendarSystem: String
    let bikramSambatDateString: String
    let locationName: String
    let latitude: String
    let longitude: String
    let timezoneString: String
    let ayanamsaName: String
    let ayanamsaValueDMS: String
    let nodeCalculation: String
    let sunriseString: String
    let sunsetString: String
    let lagnaPosition: PlanetPosition
    let planets: [PlanetPosition]
    let bhavas: [BhavaData]
    let vargas: [VargaChart]
    let shadbala: [ShadbalaBreakdown]
    let ashtakavarga: AshtakavargaData
    let dashaNodes: [DashaNode]
    let currentDashaVector: String
    let yogas: [YogaRecord]
    let sarvatobhadra: SarvatobhadraData
    let kota: KotaChakraData
    var notes: [ChartNote]
    var predictions: [PredictionRecord]

    // Fields below were added after the first schema. They are optional so that
    // chart JSON written by earlier builds still decodes.

    /// Birth instant in UTC; the reference for every dasha and upagraha timing.
    var utcBirthDate: Date? = nil
    /// Sunrise of the Jyotish day of birth (the sunrise preceding the birth), in UTC.
    var sunriseDate: Date? = nil
    /// Sunset following `sunriseDate`, in UTC.
    var sunsetDate: Date? = nil
    /// Weekday counted from sunrise to sunrise.
    var vara: Vara? = nil
    /// Gulika and Maandi in the D-1 chart.
    var upagrahas: [UpagrahaPosition]? = nil
    /// Chara karakas, arudha padas, karakamsa, and the special lagnas.
    var jaimini: JaiminiData? = nil
    var yoginiDasha: DashaTimeline? = nil
    var charaDasha: DashaTimeline? = nil
    var lagnamsaDasha: DashaTimeline? = nil

    /// Timelines of every alternative dasha system that has been computed, in menu order.
    var alternativeDashaTimelines: [DashaTimeline] {
        [yoginiDasha, charaDasha, lagnamsaDasha].compactMap { $0 }
    }
}

// MARK: - Verified Golden Fixtures

enum GoldenChartFixtures {
    static let tagoreID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    static let gandhiID = UUID(uuidString: "66666666-7777-8888-9999-000000000000")!

    static let tagore = ChartDetail(
        id: tagoreID,
        name: "Rabindranath Tagore",
        gender: "Male",
        birthDate: Calendar.current.date(from: DateComponents(year: 1861, month: 5, day: 7, hour: 4, minute: 2, second: 14))!,
        birthTimeString: "04:02:14 LMT",
        calendarSystem: "A.D. (Gregorian)",
        bikramSambatDateString: "26 Baisakh 1918 B.S.",
        locationName: "Kolkata, West Bengal, India",
        latitude: "22° 34' 11\" N",
        longitude: "88° 21' 49\" E",
        timezoneString: "LMT (Calcutta Mean Time) UTC+05:53:28",
        ayanamsaName: "Lahiri (Chitra Paksha)",
        ayanamsaValueDMS: "21° 54' 42\"",
        nodeCalculation: "True Node",
        sunriseString: "05:14 AM",
        sunsetString: "06:18 PM",
        lagnaPosition: PlanetPosition(
            graha: .ascendant,
            rasi: .pisces,
            longitudeInRasi: 2.2333,
            formattedDMS: "02° 14' 00\"",
            nakshatra: .purvaBhadrapada,
            pada: 4,
            isRetrograde: false,
            isCombust: false,
            dignity: .neutral,
            bhava: 1,
            charaKaraka: nil,
            speedDegPerDay: nil
        ),
        planets: [
            PlanetPosition(graha: .sun, rasi: .aries, longitudeInRasi: 23.7333, formattedDMS: "23° 44' 00\"", nakshatra: .bharani, pada: 4, isRetrograde: false, isCombust: false, dignity: .exalted, bhava: 2, charaKaraka: .amatyakaraka, speedDegPerDay: 0.98),
            PlanetPosition(graha: .moon, rasi: .pisces, longitudeInRasi: 11.8000, formattedDMS: "11° 48' 00\"", nakshatra: .revati, pada: 4, isRetrograde: false, isCombust: false, dignity: .neutral, bhava: 1, charaKaraka: .putrakaraka, speedDegPerDay: 12.35),
            PlanetPosition(graha: .mars, rasi: .taurus, longitudeInRasi: 20.7000, formattedDMS: "20° 42' 00\"", nakshatra: .rohini, pada: 4, isRetrograde: false, isCombust: false, dignity: .neutral, bhava: 3, charaKaraka: .bhratrukaraka, speedDegPerDay: 0.65),
            PlanetPosition(graha: .mercury, rasi: .aries, longitudeInRasi: 4.3500, formattedDMS: "04° 21' 00\"", nakshatra: .ashwini, pada: 2, isRetrograde: true, isCombust: false, dignity: .neutral, bhava: 2, charaKaraka: .darakaraka, speedDegPerDay: -0.42),
            PlanetPosition(graha: .jupiter, rasi: .cancer, longitudeInRasi: 18.4166, formattedDMS: "18° 25' 00\"", nakshatra: .pushya, pada: 2, isRetrograde: true, isCombust: false, dignity: .exalted, bhava: 5, charaKaraka: .matrukaraka, speedDegPerDay: -0.08),
            PlanetPosition(graha: .venus, rasi: .aries, longitudeInRasi: 25.2000, formattedDMS: "25° 12' 00\"", nakshatra: .bharani, pada: 4, isRetrograde: false, isCombust: false, dignity: .neutral, bhava: 2, charaKaraka: .atmakaraka, speedDegPerDay: 1.15),
            PlanetPosition(graha: .saturn, rasi: .leo, longitudeInRasi: 8.8666, formattedDMS: "08° 52' 00\"", nakshatra: .magha, pada: 3, isRetrograde: true, isCombust: false, dignity: .enemy, bhava: 6, charaKaraka: .gnatikaraka, speedDegPerDay: -0.04),
            PlanetPosition(graha: .rahu, rasi: .leo, longitudeInRasi: 15.4000, formattedDMS: "15° 24' 00\"", nakshatra: .purvaPhalguni, pada: 1, isRetrograde: true, isCombust: false, dignity: .friend, bhava: 6, charaKaraka: nil, speedDegPerDay: -0.05),
            PlanetPosition(graha: .ketu, rasi: .aquarius, longitudeInRasi: 15.4000, formattedDMS: "15° 24' 00\"", nakshatra: .shatabhisha, pada: 3, isRetrograde: true, isCombust: false, dignity: .friend, bhava: 12, charaKaraka: nil, speedDegPerDay: -0.05)
        ],
        bhavas: [
            BhavaData(number: 1, rasi: .pisces, cuspLongitudeDMS: "02° 14' 00\"", lord: .jupiter, occupantGrahas: [.moon], name: "Tanu Bhava", significance: "Self, constitution, character"),
            BhavaData(number: 2, rasi: .aries, cuspLongitudeDMS: "02° 40' 00\"", lord: .mars, occupantGrahas: [.sun, .mercury, .venus], name: "Dhana Bhava", significance: "Speech, poetry, accumulated wealth"),
            BhavaData(number: 3, rasi: .taurus, cuspLongitudeDMS: "01° 15' 00\"", lord: .venus, occupantGrahas: [.mars], name: "Sahaja Bhava", significance: "Courage, writing skills, artistic expression"),
            BhavaData(number: 4, rasi: .gemini, cuspLongitudeDMS: "28° 42' 00\"", lord: .mercury, occupantGrahas: [], name: "Sukha Bhava", significance: "Mother, home, foundational learning"),
            BhavaData(number: 5, rasi: .cancer, cuspLongitudeDMS: "26° 55' 00\"", lord: .moon, occupantGrahas: [.jupiter], name: "Putra Bhava", significance: "Genius intellect, creative poetry, intuition"),
            BhavaData(number: 6, rasi: .leo, cuspLongitudeDMS: "28° 10' 00\"", lord: .sun, occupantGrahas: [.saturn, .rahu], name: "Ari Bhava", significance: "Enemies, obstacles, competitive vitality"),
            BhavaData(number: 7, rasi: .libra, cuspLongitudeDMS: "02° 14' 00\"", lord: .venus, occupantGrahas: [], name: "Yuvati Bhava", significance: "Spouse, partnership, foreign travel"),
            BhavaData(number: 8, rasi: .scorpio, cuspLongitudeDMS: "02° 40' 00\"", lord: .mars, occupantGrahas: [], name: "Randhra Bhava", significance: "Longevity, mysticism, transformation"),
            BhavaData(number: 9, rasi: .sagittarius, cuspLongitudeDMS: "01° 15' 00\"", lord: .jupiter, occupantGrahas: [], name: "Dharma Bhava", significance: "Dharma, philosophy, higher guidance"),
            BhavaData(number: 10, rasi: .capricorn, cuspLongitudeDMS: "28° 42' 00\"", lord: .saturn, occupantGrahas: [], name: "Karma Bhava", significance: "Career, fame, world renown"),
            BhavaData(number: 11, rasi: .aquarius, cuspLongitudeDMS: "26° 55' 00\"", lord: .saturn, occupantGrahas: [], name: "Labha Bhava", significance: "Gains, honours, fulfillment"),
            BhavaData(number: 12, rasi: .pisces, cuspLongitudeDMS: "28° 10' 00\"", lord: .jupiter, occupantGrahas: [.ketu], name: "Vyaya Bhava", significance: "Moksha, transcendence, solitude")
        ],
        vargas: [
            VargaChart(division: .d1, lagnaRasi: .pisces, planetRasis: [.sun: .aries, .moon: .pisces, .mars: .taurus, .mercury: .aries, .jupiter: .cancer, .venus: .aries, .saturn: .leo, .rahu: .leo, .ketu: .aquarius]),
            VargaChart(division: .d9, lagnaRasi: .cancer, planetRasis: [.sun: .sagittarius, .moon: .cancer, .mars: .scorpio, .mercury: .taurus, .jupiter: .cancer, .venus: .scorpio, .saturn: .gemini, .rahu: .leo, .ketu: .aquarius])
        ],
        shadbala: [
            ShadbalaBreakdown(graha: .jupiter, sthanaBala: 215.0, dikBala: 52.0, kalaBala: 260.0, cheshtaBala: 54.0, naisargikaBala: 51.4, drikBala: 17.6, totalVirupas: 650.0, totalRupas: 1.42, requiredRupas: 1.00, rank: 1),
            ShadbalaBreakdown(graha: .sun, sthanaBala: 198.0, dikBala: 48.0, kalaBala: 242.0, cheshtaBala: 48.0, naisargikaBala: 60.0, drikBala: 14.0, totalVirupas: 610.0, totalRupas: 1.35, requiredRupas: 1.00, rank: 2),
            ShadbalaBreakdown(graha: .venus, sthanaBala: 185.0, dikBala: 42.0, kalaBala: 230.0, cheshtaBala: 46.0, naisargikaBala: 42.8, drikBala: 13.2, totalVirupas: 559.0, totalRupas: 1.28, requiredRupas: 1.00, rank: 3),
            ShadbalaBreakdown(graha: .mars, sthanaBala: 172.0, dikBala: 38.0, kalaBala: 215.0, cheshtaBala: 41.0, naisargikaBala: 25.7, drikBala: 12.3, totalVirupas: 504.0, totalRupas: 1.18, requiredRupas: 1.00, rank: 4),
            ShadbalaBreakdown(graha: .moon, sthanaBala: 165.0, dikBala: 35.0, kalaBala: 195.0, cheshtaBala: 38.0, naisargikaBala: 51.4, drikBala: 10.6, totalVirupas: 495.0, totalRupas: 1.12, requiredRupas: 1.00, rank: 5),
            ShadbalaBreakdown(graha: .mercury, sthanaBala: 154.0, dikBala: 41.0, kalaBala: 188.0, cheshtaBala: 45.0, naisargikaBala: 34.3, drikBala: 11.7, totalVirupas: 474.0, totalRupas: 1.06, requiredRupas: 1.00, rank: 6),
            ShadbalaBreakdown(graha: .saturn, sthanaBala: 140.0, dikBala: 30.0, kalaBala: 175.0, cheshtaBala: 35.0, naisargikaBala: 17.1, drikBala: 8.9, totalVirupas: 406.0, totalRupas: 0.95, requiredRupas: 1.00, rank: 7)
        ],
        ashtakavarga: AshtakavargaData(
            sarvashtakavarga: [
                .aries: 31, .taurus: 28, .gemini: 32, .cancer: 34,
                .leo: 29, .virgo: 25, .libra: 30, .scorpio: 24,
                .sagittarius: 26, .capricorn: 27, .aquarius: 26, .pisces: 25
            ],
            bhinnashtakavarga: [
                .sun: [.aries: 5, .taurus: 4, .gemini: 5, .cancer: 5, .leo: 4, .virgo: 3, .libra: 4, .scorpio: 3, .sagittarius: 4, .capricorn: 4, .aquarius: 4, .pisces: 3],
                .moon: [.aries: 4, .taurus: 4, .gemini: 5, .cancer: 6, .leo: 4, .virgo: 3, .libra: 4, .scorpio: 3, .sagittarius: 4, .capricorn: 4, .aquarius: 4, .pisces: 4],
                .jupiter: [.aries: 5, .taurus: 4, .gemini: 5, .cancer: 6, .leo: 5, .virgo: 4, .libra: 5, .scorpio: 4, .sagittarius: 4, .capricorn: 5, .aquarius: 4, .pisces: 5]
            ]
        ),
        dashaNodes: [
            DashaNode(
                level: .mahadasha,
                lord: .mercury,
                startDate: Calendar.current.date(from: DateComponents(year: 1861, month: 5, day: 7))!,
                endDate: Calendar.current.date(from: DateComponents(year: 1871, month: 5, day: 7))!,
                formattedDuration: "10y 0m (Bal)",
                ageAtStart: 0.0,
                statusText: "Completed",
                role: "4th & 7th Lord"
            ),
            DashaNode(
                level: .mahadasha,
                lord: .ketu,
                startDate: Calendar.current.date(from: DateComponents(year: 1871, month: 5, day: 7))!,
                endDate: Calendar.current.date(from: DateComponents(year: 1878, month: 5, day: 7))!,
                formattedDuration: "7y 0m",
                ageAtStart: 10.0,
                statusText: "Completed",
                role: "Moksha Karaka"
            ),
            DashaNode(
                level: .mahadasha,
                lord: .venus,
                startDate: Calendar.current.date(from: DateComponents(year: 1878, month: 5, day: 7))!,
                endDate: Calendar.current.date(from: DateComponents(year: 1898, month: 5, day: 7))!,
                formattedDuration: "20y 0m",
                ageAtStart: 17.0,
                statusText: "Completed",
                role: "3rd & 8th Lord"
            ),
            DashaNode(
                level: .mahadasha,
                lord: .sun,
                startDate: Calendar.current.date(from: DateComponents(year: 1898, month: 5, day: 7))!,
                endDate: Calendar.current.date(from: DateComponents(year: 1904, month: 5, day: 7))!,
                formattedDuration: "6y 0m",
                ageAtStart: 37.0,
                statusText: "Focused",
                role: "6th Lord · Exalted in 2nd",
                children: [
                    DashaNode(
                        level: .antardasha,
                        lord: .venus,
                        startDate: Calendar.current.date(from: DateComponents(year: 1901, month: 5, day: 7))!,
                        endDate: Calendar.current.date(from: DateComponents(year: 1902, month: 5, day: 7))!,
                        formattedDuration: "1y 0m",
                        ageAtStart: 40.0,
                        statusText: "Focused",
                        role: "3rd & 8th Lord",
                        children: [
                            DashaNode(
                                level: .pratyantardasha,
                                lord: .mercury,
                                startDate: Calendar.current.date(from: DateComponents(year: 1902, month: 1, day: 22))!,
                                endDate: Calendar.current.date(from: DateComponents(year: 1902, month: 3, day: 8))!,
                                formattedDuration: "45d",
                                ageAtStart: 40.7,
                                statusText: "Active",
                                role: "4th & 7th Lord"
                            )
                        ]
                    )
                ]
            ),
            DashaNode(
                level: .mahadasha,
                lord: .moon,
                startDate: Calendar.current.date(from: DateComponents(year: 1904, month: 5, day: 7))!,
                endDate: Calendar.current.date(from: DateComponents(year: 1914, month: 5, day: 7))!,
                formattedDuration: "10y 0m",
                ageAtStart: 43.0,
                statusText: "Upcoming",
                role: "5th Lord in 1st"
            )
        ],
        currentDashaVector: "Sun › Venus › Mercury › Jupiter › Mars",
        yogas: [
            YogaRecord(
                name: "Hamsa Mahapurusha Yoga",
                category: "Pancha Mahapurusha",
                participatingGrahas: [.jupiter],
                description: "Jupiter is exalted in Cancer in the 5th trikona from Lagna, granting immense spiritual wisdom and noble character.",
                referenceSource: "BPHS Ch. 35",
                isAuspicious: true,
                cancellationNote: nil
            ),
            YogaRecord(
                name: "Gajakesari Yoga",
                category: "Auspicious",
                participatingGrahas: [.jupiter, .moon],
                description: "Jupiter is in the 5th house from the Moon, ensuring lasting literary renown and unblemished reputation.",
                referenceSource: "BPHS Ch. 36",
                isAuspicious: true,
                cancellationNote: nil
            ),
            YogaRecord(
                name: "Budhaditya Yoga",
                category: "Raja Yoga",
                participatingGrahas: [.sun, .mercury],
                description: "Conjunction of exalted Sun and Mercury in the 2nd house of speech and poetic expression, conferring dazzling verbal brilliance.",
                referenceSource: "Saravali Ch. 31",
                isAuspicious: true,
                cancellationNote: nil
            )
        ],
        sarvatobhadra: SarvatobhadraData(
            cells: [],
            vedhas: [
                "Sun in Bharani casts Front Vedha on Anuradha",
                "Jupiter in Pushya casts Right Vedha on Purva Phalguni",
                "Mars in Rohini casts Left Vedha on Abhijit"
            ]
        ),
        kota: KotaChakraData(
            kotaSwami: .jupiter,
            kotaPala: .moon,
            zoneAssignments: [
                .stambha: [.jupiter],
                .madhya: [.moon, .sun],
                .prakara: [.mercury, .venus],
                .bahya: [.mars, .saturn, .rahu, .ketu]
            ],
            praveshaGrahas: [.jupiter, .sun, .moon],
            nirgamaGrahas: [.mars, .saturn]
        ),
        notes: [
            ChartNote(
                id: UUID(),
                date: Calendar.current.date(from: DateComponents(year: 1902, month: 4, day: 14))!,
                category: "Clinical Observation",
                content: "Ashram at Santiniketan expands rapidly during Sun-Venus period.",
                tags: ["#Santiniketan", "#Gitanjali"]
            )
        ],
        predictions: [
            PredictionRecord(
                id: UUID(),
                title: "Nobel Prize in Literature Recognition",
                targetDate: Calendar.current.date(from: DateComponents(year: 1913, month: 11, day: 13))!,
                status: .confirmed,
                dashaContext: "Moon Mahadasha / Jupiter Antardasha",
                details: "Awarded the 1913 Nobel Prize in Literature for Gitanjali."
            )
        ]
    )

    static let gandhi = ChartDetail(
        id: gandhiID,
        name: "Mahatma Gandhi",
        gender: "Male",
        birthDate: Calendar.current.date(from: DateComponents(year: 1869, month: 10, day: 2, hour: 7, minute: 11, second: 0))!,
        birthTimeString: "07:11:00 LMT",
        calendarSystem: "A.D. (Gregorian)",
        bikramSambatDateString: "18 Ashwin 1926 B.S.",
        locationName: "Porbandar, Gujarat, India",
        latitude: "21° 38' 00\" N",
        longitude: "69° 36' 00\" E",
        timezoneString: "LMT (Porbandar) UTC+04:38:24",
        ayanamsaName: "Lahiri (Chitra Paksha)",
        ayanamsaValueDMS: "22° 01' 14\"",
        nodeCalculation: "True Node",
        sunriseString: "06:22 AM",
        sunsetString: "06:24 PM",
        lagnaPosition: PlanetPosition(
            graha: .ascendant,
            rasi: .libra,
            longitudeInRasi: 12.0,
            formattedDMS: "12° 00' 00\"",
            nakshatra: .swati,
            pada: 2,
            isRetrograde: false,
            isCombust: false,
            dignity: .neutral,
            bhava: 1,
            charaKaraka: nil,
            speedDegPerDay: nil
        ),
        planets: [
            PlanetPosition(graha: .sun, rasi: .virgo, longitudeInRasi: 16.9166, formattedDMS: "16° 55' 00\"", nakshatra: .hasta, pada: 3, isRetrograde: false, isCombust: false, dignity: .neutral, bhava: 12, charaKaraka: .putrakaraka, speedDegPerDay: 0.98),
            PlanetPosition(graha: .moon, rasi: .cancer, longitudeInRasi: 28.1666, formattedDMS: "28° 10' 00\"", nakshatra: .ashlesha, pada: 4, isRetrograde: false, isCombust: false, dignity: .ownSign, bhava: 10, charaKaraka: .atmakaraka, speedDegPerDay: 13.5),
            PlanetPosition(graha: .mars, rasi: .libra, longitudeInRasi: 26.3666, formattedDMS: "26° 22' 00\"", nakshatra: .vishakha, pada: 2, isRetrograde: false, isCombust: false, dignity: .neutral, bhava: 1, charaKaraka: .amatyakaraka, speedDegPerDay: 0.68),
            PlanetPosition(graha: .mercury, rasi: .libra, longitudeInRasi: 11.75, formattedDMS: "11° 45' 00\"", nakshatra: .swati, pada: 2, isRetrograde: false, isCombust: false, dignity: .friend, bhava: 1, charaKaraka: .darakaraka, speedDegPerDay: 1.2),
            PlanetPosition(graha: .jupiter, rasi: .aries, longitudeInRasi: 28.1333, formattedDMS: "28° 08' 00\"", nakshatra: .krittika, pada: 1, isRetrograde: true, isCombust: false, dignity: .friend, bhava: 7, charaKaraka: .bhratrukaraka, speedDegPerDay: -0.07),
            PlanetPosition(graha: .venus, rasi: .libra, longitudeInRasi: 24.4333, formattedDMS: "24° 26' 00\"", nakshatra: .vishakha, pada: 2, isRetrograde: false, isCombust: false, dignity: .ownSign, bhava: 1, charaKaraka: .matrukaraka, speedDegPerDay: 1.1),
            PlanetPosition(graha: .saturn, rasi: .scorpio, longitudeInRasi: 20.3166, formattedDMS: "20° 19' 00\"", nakshatra: .jyeshtha, pada: 2, isRetrograde: false, isCombust: false, dignity: .enemy, bhava: 2, charaKaraka: .gnatikaraka, speedDegPerDay: 0.05),
            PlanetPosition(graha: .rahu, rasi: .cancer, longitudeInRasi: 12.1333, formattedDMS: "12° 08' 00\"", nakshatra: .pushya, pada: 3, isRetrograde: true, isCombust: false, dignity: .enemy, bhava: 10, charaKaraka: nil, speedDegPerDay: -0.05),
            PlanetPosition(graha: .ketu, rasi: .capricorn, longitudeInRasi: 12.1333, formattedDMS: "12° 08' 00\"", nakshatra: .shatabhisha, pada: 1, isRetrograde: true, isCombust: false, dignity: .enemy, bhava: 4, charaKaraka: nil, speedDegPerDay: -0.05)
        ],
        bhavas: (1...12).map { num in
            BhavaData(
                number: num,
                rasi: Rasi(rawValue: ((num + 6) % 12) + 1) ?? .libra,
                cuspLongitudeDMS: "12° 00' 00\"",
                lord: .venus,
                occupantGrahas: (num == 1) ? [.mars, .mercury, .venus] : [],
                name: "House \(num)",
                significance: "Bhava \(num)"
            )
        },
        vargas: [
            VargaChart(division: .d1, lagnaRasi: .libra, planetRasis: [.sun: .virgo, .moon: .cancer, .mars: .libra, .mercury: .libra, .jupiter: .aries, .venus: .libra, .saturn: .scorpio, .rahu: .cancer, .ketu: .capricorn])
        ],
        shadbala: [
            ShadbalaBreakdown(graha: .venus, sthanaBala: 190.0, dikBala: 40.0, kalaBala: 220.0, cheshtaBala: 42.0, naisargikaBala: 42.8, drikBala: 12.0, totalVirupas: 546.8, totalRupas: 1.25, requiredRupas: 1.00, rank: 1)
        ],
        ashtakavarga: AshtakavargaData(
            sarvashtakavarga: [
                .aries: 29, .taurus: 30, .gemini: 27, .cancer: 33,
                .leo: 26, .virgo: 28, .libra: 32, .scorpio: 24,
                .sagittarius: 28, .capricorn: 25, .aquarius: 27, .pisces: 28
            ],
            bhinnashtakavarga: [:]
        ),
        dashaNodes: [
            DashaNode(
                level: .mahadasha,
                lord: .jupiter,
                startDate: Calendar.current.date(from: DateComponents(year: 1918, month: 10, day: 2))!,
                endDate: Calendar.current.date(from: DateComponents(year: 1934, month: 10, day: 2))!,
                formattedDuration: "16y 0m",
                ageAtStart: 49.0,
                statusText: "Active",
                role: "3rd & 6th Lord"
            )
        ],
        currentDashaVector: "Jupiter › Saturn › Ketu",
        yogas: [
            YogaRecord(
                name: "Malavya Mahapurusha Yoga",
                category: "Pancha Mahapurusha",
                participatingGrahas: [.venus],
                description: "Venus in own sign Libra in 1st Kendra house, endowing remarkable charm and peace-loving conviction.",
                referenceSource: "BPHS Ch. 35",
                isAuspicious: true,
                cancellationNote: nil
            )
        ],
        sarvatobhadra: SarvatobhadraData(cells: [], vedhas: []),
        kota: KotaChakraData(
            kotaSwami: .moon,
            kotaPala: .venus,
            zoneAssignments: [.stambha: [.moon], .madhya: [.venus], .prakara: [.mercury], .bahya: [.mars]],
            praveshaGrahas: [.moon],
            nirgamaGrahas: [.mars]
        ),
        notes: [],
        predictions: []
    )
}

