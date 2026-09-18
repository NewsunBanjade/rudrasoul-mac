import Foundation

// Shared value types for upagrahas, Jaimini data, alternative dashas, and
// chakra cells. Everything here is a pure, Codable value so that `ChartDetail`
// keeps round-tripping through the SQLite `raw_chart_json` column.
//
// Every property added to an existing stored type is optional so that charts
// saved before these features existed still decode.

// MARK: - Vara (weekday)

/// The weekday of a birth counted from sunrise to sunrise, as Jyotish requires.
enum Vara: Int, CaseIterable, Identifiable, Sendable, Codable {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .sunday: "Sunday"
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        }
    }

    var sanskritName: String {
        switch self {
        case .sunday: "Ravivara"
        case .monday: "Somavara"
        case .tuesday: "Mangalavara"
        case .wednesday: "Budhavara"
        case .thursday: "Guruvara"
        case .friday: "Shukravara"
        case .saturday: "Shanivara"
        }
    }

    /// The planetary lord of the weekday in the fixed hora order.
    var lord: Graha {
        switch self {
        case .sunday: .sun
        case .monday: .moon
        case .tuesday: .mars
        case .wednesday: .mercury
        case .thursday: .jupiter
        case .friday: .venus
        case .saturday: .saturn
        }
    }

    /// The seven weekday lords in weekday order, starting from Sunday.
    static let lordSequence: [Graha] = Vara.allCases.map(\.lord)
}

// MARK: - Upagrahas (Gulika, Maandi)

enum UpagrahaKind: String, CaseIterable, Identifiable, Sendable, Codable {
    case gulika = "Gulika"
    case maandi = "Maandi"

    var id: String { rawValue }

    var shortAbbreviation: String {
        switch self {
        case .gulika: "Gk"
        case .maandi: "Md"
        }
    }
}

/// A sidereal position of a shadow point that has no ephemeris body.
struct UpagrahaPosition: Identifiable, Hashable, Sendable, Codable {
    var id: String { kind.rawValue }
    let kind: UpagrahaKind
    /// Absolute sidereal longitude in decimal degrees, 0 ..< 360.
    let longitude: Double
    let rasi: Rasi
    let longitudeInRasi: Double
    let formattedDMS: String
    let nakshatra: Nakshatra
    let pada: Int
    let bhava: Int
    /// The civil instant at which this point rose, in UTC.
    let risingDate: Date
}

// MARK: - Special lagnas

enum SpecialLagnaKind: String, CaseIterable, Identifiable, Sendable, Codable {
    case bhavaLagna = "Bhava Lagna"
    case horaLagna = "Hora Lagna"
    case ghatiLagna = "Ghati Lagna"
    case induLagna = "Indu Lagna"
    case sreeLagna = "Sree Lagna"
    case varnadaLagna = "Varnada Lagna"

    var id: String { rawValue }

    var shortAbbreviation: String {
        switch self {
        case .bhavaLagna: "BL"
        case .horaLagna: "HL"
        case .ghatiLagna: "GL"
        case .induLagna: "IL"
        case .sreeLagna: "SL"
        case .varnadaLagna: "VL"
        }
    }
}

struct SpecialLagnaPosition: Identifiable, Hashable, Sendable, Codable {
    var id: String { kind.rawValue }
    let kind: SpecialLagnaKind
    /// Absolute sidereal longitude in decimal degrees, 0 ..< 360.
    let longitude: Double
    let rasi: Rasi
    let longitudeInRasi: Double
    let formattedDMS: String
}

// MARK: - Jaimini

/// Which planets take part in the chara karaka scheme.
enum CharaKarakaScheme: String, CaseIterable, Sendable, Codable {
    /// Seven karakas from Sun through Saturn (Rahu excluded).
    case sevenKarakas = "7 karakas"
    /// Eight karakas including Rahu, whose degree is counted from the end of its sign.
    case eightKarakas = "8 karakas"
}

/// An arudha (pada) of a bhava: the sign as far from the bhava lord as the lord is from the bhava.
struct ArudhaPada: Identifiable, Hashable, Sendable, Codable {
    var id: Int { house }
    /// The bhava (1–12) whose pada this is.
    let house: Int
    /// Display name such as "AL", "A2", "UL".
    let name: String
    let rasi: Rasi
    /// The bhava lord used for the count.
    let lord: Graha
    /// True when the exception rule moved the pada (never when exceptions are off).
    let exceptionApplied: Bool
}

struct JaiminiData: Hashable, Sendable, Codable {
    let scheme: CharaKarakaScheme
    /// Karaka → planet. Contains seven or eight entries depending on `scheme`.
    let charaKarakas: [CharaKaraka: Graha]
    /// Arudha padas for bhavas 1–12, in house order.
    let arudhaPadas: [ArudhaPada]
    /// Whether the classical same-sign / seventh-sign exception was applied to the padas.
    let arudhaExceptionsApplied: Bool
    /// Navamsa sign of the Atmakaraka (Karakamsa / Swamsa).
    let karakamsaRasi: Rasi?
    /// Navamsa sign of the Lagna (Lagnamsa).
    let lagnamsaRasi: Rasi?
    /// Bhava, Hora, Ghati, Indu, Sree, and Varnada lagnas that could be computed.
    let specialLagnas: [SpecialLagnaPosition]
}

// MARK: - Shashtiamsa (D-60) deities

/// The deity ruling one of the sixty Shashtiamsas of a sign.
struct ShashtiamsaDetail: Hashable, Sendable, Codable {
    /// 1 ... 60 within the natal sign.
    let index: Int
    let deity: String
    let isBenefic: Bool
}

// MARK: - Alternative dasha systems

enum DashaSystem: String, CaseIterable, Identifiable, Sendable, Codable {
    case vimshottari = "Vimshottari"
    case yogini = "Yogini"
    case chara = "Chara"
    case lagnamsa = "Lagnamsa"

    var id: String { rawValue }
}

/// The eight Yoginis of the 36-year Yogini dasha and their planetary lords.
enum Yogini: Int, CaseIterable, Identifiable, Sendable, Codable {
    case mangala = 1, pingala, dhanya, bhramari, bhadrika, ulka, siddha, sankata

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .mangala: "Mangala"
        case .pingala: "Pingala"
        case .dhanya: "Dhanya"
        case .bhramari: "Bhramari"
        case .bhadrika: "Bhadrika"
        case .ulka: "Ulka"
        case .siddha: "Siddha"
        case .sankata: "Sankata"
        }
    }

    var lord: Graha {
        switch self {
        case .mangala: .moon
        case .pingala: .sun
        case .dhanya: .jupiter
        case .bhramari: .mars
        case .bhadrika: .mercury
        case .ulka: .saturn
        case .siddha: .venus
        case .sankata: .rahu
        }
    }

    /// Duration in years; equals the Yogini's ordinal.
    var years: Int { rawValue }
}

/// One period of any dasha system. Sub-periods live in `children`.
struct DashaPeriod: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    let system: DashaSystem
    /// 1 = mahadasha, 2 = antardasha, 3 = pratyantardasha, and so on.
    let level: Int
    /// Display name of the period lord: a planet, a sign, or a Yogini.
    let name: String
    let graha: Graha?
    let rasi: Rasi?
    let startDate: Date
    let endDate: Date
    var children: [DashaPeriod]

    init(
        id: UUID = UUID(),
        system: DashaSystem,
        level: Int,
        name: String,
        graha: Graha? = nil,
        rasi: Rasi? = nil,
        startDate: Date,
        endDate: Date,
        children: [DashaPeriod] = []
    ) {
        self.id = id
        self.system = system
        self.level = level
        self.name = name
        self.graha = graha
        self.rasi = rasi
        self.startDate = startDate
        self.endDate = endDate
        self.children = children
    }

    var durationDays: Double { endDate.timeIntervalSince(startDate) / 86_400 }

    func contains(_ date: Date) -> Bool { date >= startDate && date < endDate }
}

/// A complete dasha sequence of one system for one chart.
struct DashaTimeline: Hashable, Sendable, Codable {
    let system: DashaSystem
    /// Days per dasha year used to lay out the periods.
    let yearLengthDays: Double
    /// Human-readable derivation, e.g. "Moon in Revati · Sankata balance 2y 4m".
    let derivationNote: String
    let periods: [DashaPeriod]

    /// The chain of periods running at `date`, outermost first.
    func activePath(at date: Date) -> [DashaPeriod] {
        var path: [DashaPeriod] = []
        var candidates = periods
        while let match = candidates.first(where: { $0.contains(date) }) {
            path.append(match)
            candidates = match.children
        }
        return path
    }
}

// MARK: - Kota Chakra cells

/// One of the 28 nakshatra cells of the Kota Chakra, counted from the Janma nakshatra.
struct KotaCell: Identifiable, Hashable, Sendable, Codable {
    var id: Int { sequence }
    /// 1 ... 28 counted from the Janma nakshatra (1 = Janma).
    let sequence: Int
    let nakshatra: Nakshatra
    let zone: KotaChakraData.Zone
    let grahas: [Graha]
}

// MARK: - Sarvatobhadra vedhas

struct SarvatobhadraVedha: Identifiable, Hashable, Sendable, Codable {
    enum Direction: String, Sendable, Codable {
        case front = "Front"
        case left = "Left"
        case right = "Right"
    }

    var id: String { "\(graha.rawValue)-\(direction.rawValue)-\(targetLabel)" }
    let graha: Graha
    let sourceNakshatra: Nakshatra
    let direction: Direction
    /// The label of the struck cell: a nakshatra, a rasi, a tithi group, or a letter.
    let targetLabel: String
    let isBenefic: Bool
}

// MARK: - Planetary relationships

/// The compound (panchadha maitri) relationship of one planet with another, BPHS Ch. 3, vv. 58–59.
enum PlanetaryRelation: String, CaseIterable, Sendable, Codable {
    case adhiMitra = "Adhi Mitra"
    case mitra = "Mitra"
    case sama = "Sama"
    case shatru = "Shatru"
    case adhiShatru = "Adhi Shatru"

    /// The sign dignity a planet has when the lord of its sign bears this relationship to it.
    var dignity: Dignity {
        switch self {
        case .adhiMitra: .greatFriend
        case .mitra: .friend
        case .sama: .neutral
        case .shatru: .enemy
        case .adhiShatru: .greatEnemy
        }
    }

    var shortLabel: String {
        switch self {
        case .adhiMitra: "AM"
        case .mitra: "M"
        case .sama: "S"
        case .shatru: "E"
        case .adhiShatru: "AE"
        }
    }
}

// MARK: - Shadbala components

/// The individual virupa contributions that make up a planet's Shadbala (BPHS Ch. 27).
struct ShadbalaComponents: Hashable, Sendable, Codable {
    // Sthana Bala
    let ucchaBala: Double
    let saptavargajaBala: Double
    let ojayugmaBala: Double
    let kendradiBala: Double
    let drekkanaBala: Double
    // Kala Bala
    let nathonnathaBala: Double
    let pakshaBala: Double
    let tribhagaBala: Double
    let abdaBala: Double
    let masaBala: Double
    let varaBala: Double
    let horaBala: Double
    let ayanaBala: Double
    /// How the Cheshta bala was obtained, e.g. "Chesta kendra 123.4°" or "Equals Ayana bala".
    let cheshtaNote: String
}

/// Strength of one house: lord's Shadbala, directional strength and aspects (BPHS Ch. 28).
struct BhavaBala: Identifiable, Hashable, Sendable, Codable {
    var id: Int { house }
    let house: Int
    let rasi: Rasi
    let lord: Graha
    let bhavadhipatiBala: Double
    let bhavaDigBala: Double
    let bhavaDrishtiBala: Double
    let totalVirupas: Double
    let rank: Int

    var totalRupas: Double { totalVirupas / 60 }
}
