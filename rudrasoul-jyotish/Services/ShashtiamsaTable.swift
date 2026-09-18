import Foundation

/// The sixty Shashtiamsa (D-60) deities of a sign and their benefic or malefic nature.
///
/// Rule (Brihat Parashara Hora Shastra, Ch. 6, vv. 33–41, R. Santhanam translation):
/// every sign is divided into sixty equal parts of 0°30' each. To find the part a
/// planet occupies, ignore its sign and take the degrees it has traversed in that
/// sign; each full half-degree advances the part by one. In odd signs (Aries,
/// Gemini, …) the deities are counted forward from Ghora (1st) to Chandrarekha
/// (60th); in even signs (Taurus, Cancer, …) "the reverse is the order", so the
/// first half-degree of an even sign belongs to Chandrarekha and the last to Ghora.
/// Verse 41: planets in benefic Shashtiamsas produce auspicious results, planets in
/// malefic ones the opposite.
///
/// Scheme note: the product request mentioned an "unequal division" for D-60. A search
/// of BPHS commentaries and of mainstream software practice (Jagannatha Hora,
/// Parashara's Light) found no unequal Shashtiamsa scheme: the only unequal vargas in
/// use are the Trimsamsa (D-30) and the Chandra Kala Nadi Nadiamsa (D-150). Wikipedia's
/// "Shashtiamsa" entry and every consulted table define it as "equally divided, half a
/// degree each". Only the Parashari equal scheme is therefore implemented; the odd/even
/// deity ordering is the rule that carries the interpretive weight.
///
/// Name spellings follow Santhanam. Order and numbering were cross-checked against the
/// BPHS Ch. 6 transcript at astronavprayas.wordpress.com (2015/07/13, "The Sixteen
/// Divisions of a Sign") and the Sanskrit of verse 34 at enjoylearningsanskrit.com
/// (ghoraḥ rākṣasaḥ devaḥ kuberaḥ yakṣa-kinnarau bhraṣṭaḥ kulaghnaḥ garalaḥ vahniḥ
/// māyā purīṣakaḥ), which confirm Purishaka as the 12th name. No discrepancy was found.
enum ShashtiamsaTable {
    /// Number of Shashtiamsas in one sign.
    static let divisionsPerRasi = 60

    /// Width of one Shashtiamsa in degrees (30° / 60).
    static let amsaSpanDegrees: Double = 0.5

    /// The sixty deities in the order they occupy an odd sign, 1st to 60th.
    /// Several names repeat (Deva, Kaala, Ghora, Amrita, Komala, Saumya), as in the text.
    static let oddSignDeities: [String] = [
        "Ghora", "Rakshasa", "Deva", "Kubera", "Yaksha",
        "Kinnara", "Bhrashta", "Kulaghna", "Garala", "Vahni",
        "Maya", "Purishaka", "Apampathi", "Marutwan", "Kaala",
        "Sarpa", "Amrita", "Indu", "Mridu", "Komala",
        "Heramba", "Brahma", "Vishnu", "Maheshwara", "Deva",
        "Ardra", "Kalinasa", "Kshiteesa", "Kamalakara", "Gulika",
        "Mrityu", "Kaala", "Davagni", "Ghora", "Yama",
        "Kantaka", "Sudha", "Amrita", "Purnachandra", "Vishadagdha",
        "Kulanasa", "Vamshakshaya", "Utpata", "Kaala", "Saumya",
        "Komala", "Sheetala", "Karaladamshtra", "Chandramukhi", "Praveena",
        "Kaalapavaka", "Dandayudha", "Nirmala", "Saumya", "Kroora",
        "Atisheetala", "Amrita", "Payodhi", "Bhramana", "Chandrarekha"
    ]

    /// Deities whose Shashtiamsa is benefic (shubha). Every other name is malefic (kroora).
    ///
    /// BPHS itself does not enumerate the two groups; the names carry their nature
    /// (Ghora "terrible", Amrita "nectar"). This split follows the classification used in
    /// Jagannatha Hora and reproduced at shivohampath.com ("D60 Shashtiamsha: Past-Life
    /// Karma at Full Resolution"), which agrees with the Wikipedia "Shashtiamsa" table on
    /// every shared name except two noted below.
    ///
    /// Uncertain names, with the reading chosen here:
    /// - Vahni (fire): malefic in Wikipedia and shivohampath; sarvatobhadra.com lists it
    ///   benefic. Malefic chosen (majority, and consistent with Davagni and Kaalapavaka).
    /// - Ardra (moist): benefic in Wikipedia, shivohampath, and sarvatobhadra.com;
    ///   trendingastro.com marks it bad. Benefic chosen.
    /// - Kalinasa (destroyer of strife): benefic in shivohampath and sarvatobhadra.com;
    ///   Wikipedia reads the name as Kālanāsha and marks it malefic. Benefic chosen.
    /// - Dandayudha (armed with a staff): malefic in shivohampath and sarvatobhadra.com;
    ///   Wikipedia marks it benefic. Malefic chosen.
    /// - Payodhi (ocean) benefic and Bhramana (wandering) malefic in every source consulted.
    static let beneficDeities: Set<String> = [
        "Deva", "Kubera", "Yaksha", "Kinnara", "Apampathi", "Marutwan",
        "Amrita", "Indu", "Mridu", "Komala", "Heramba", "Brahma", "Vishnu",
        "Maheshwara", "Ardra", "Kalinasa", "Kshiteesa", "Kamalakara", "Sudha",
        "Purnachandra", "Saumya", "Sheetala", "Chandramukhi", "Praveena",
        "Nirmala", "Atisheetala", "Payodhi", "Chandrarekha"
    ]

    /// 1-based Shashtiamsa index (1 ... 60) of a longitude measured inside its sign.
    ///
    /// Each full 0°30' traversed advances the index by one, so 0° is the 1st amsa,
    /// 0°30' the 2nd, and 29°30' up to (but excluding) 30° the 60th. Values outside
    /// 0 ..< 30 are first wrapped into the sign.
    static func amsaIndex(longitudeInRasi: Double) -> Int {
        let withinRasi = longitudeInRasi.longitudeWithinRasi
        let zeroBased = Int(withinRasi / amsaSpanDegrees)
        return min(max(zeroBased, 0), divisionsPerRasi - 1) + 1
    }

    /// The deity of the `index`th Shashtiamsa (1 ... 60), counted forward in odd
    /// signs and backward in even signs (BPHS Ch. 6, v. 40).
    static func deity(index: Int, isOddSign: Bool) -> String {
        let clamped = min(max(index, 1), divisionsPerRasi)
        let position = isOddSign ? clamped - 1 : divisionsPerRasi - clamped
        return oddSignDeities[position]
    }

    /// Whether a deity name rules a benefic (shubha) Shashtiamsa.
    static func isBenefic(deity: String) -> Bool {
        beneficDeities.contains(deity)
    }

    /// Index, deity, and nature of the Shashtiamsa containing an absolute sidereal longitude.
    static func detail(absoluteLongitude: Double) -> ShashtiamsaDetail {
        let rasi = Rasi(absoluteLongitude: absoluteLongitude)
        let index = amsaIndex(longitudeInRasi: absoluteLongitude.longitudeWithinRasi)
        let name = deity(index: index, isOddSign: rasi.isOdd)
        return ShashtiamsaDetail(index: index, deity: name, isBenefic: isBenefic(deity: name))
    }
}
