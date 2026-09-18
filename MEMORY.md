# Jyotish Pro working memory

This is durable project context for future implementation steps. Keep it terse,
factual, and current; do not use it as a changelog.

## Authority and references

- Engineering rules: `agents.md`.
- Visual reference: `html/DESIGN.md`, `html/*/screen.png`, and corresponding
  `code.html` files.
- HTML and CSS are reference-only and must never be ported into the app.
- If the visual reference conflicts with `agents.md`, follow `agents.md`.

## Current repository state

- The app uses a single unified macOS window (`ContentView` hosting `ChartScreen`).
- The sidebar combines:
  - Library: `All Charts`, `Recent`
  - Chart: `Overview`, `Divisional Charts`, `Planets & Houses`, `Strength`, `Ashtakavarga`, `Dasha`, `Nakshatra`, `Yogas & Doshas`
  - Chakras: `Sarvatobhadra`, `Kota`
  - Tools: `Progression & Transit`, `Notes & Predictions`
- Opening or creating charts navigates in-place within the same window; no second window is opened.
- Active chart can also be quickly switched via the navigation bar menu dropdown.
- The design reference `html/` tree is visible in Xcode but intentionally not a
  target resource; bundling it causes duplicate resource output names.
- Focused DesignSystem tests pass with Swift Testing.
- `Features/Library` defines the display-data/provider contract, a main-actor
  observable screen model, and native split-view/search/table/empty-state UI.
- `Features/Chart` defines a chart-ID-addressed window shell with native analysis
  navigation, a fluid workbench, optional inspector, and model coverage.
- `DesignSystem` includes `ChartIdentityHeader`, `AppStatusBar`, `NorthIndianChartCanvas`,
  `SouthIndianChartCanvas`, `TransitDateStepper`, and `MetricTile`.
- The chart shell now renders complete, native UI pages for all analysis and chakra destinations:
  `OverviewView`, `DivisionalChartsView`, `PlanetsAndHousesView`, `StrengthView`,
  `AshtakavargaView`, `DashaView`, `NakshatraView`, `YogasAndDoshasView`,
  `SarvatobhadraView`, `KotaView`, `ProgressionTransitView`, and `NotesPredictionsView`.
- `NewChartSheet` provides chart creation with A.D./B.S. date switcher, atlas lookup, and calculation options.
- `SettingsScreen` implements macOS settings for calculation defaults, display options, and ephemeris status.
- `ChartStore` integrates with `SQLiteChartRepository.shared` (`rudrasoul-jyotish/Persistence/`):
  - Automatically loads and seeds default fixtures (Tagore & Gandhi) on first launch.
  - Persists new charts, notes, predictions, and modifications to `Application Support/rudrasoul-jyotish/jyotish.sqlite3`.
  - Schema V1 uses indexed columns for fast astrological query filtering (`lagna_rasi`, `moon_nakshatra`, `current_dasha`, `engine_version`).
  - SQLite database supports online atomic backup/restore for import and export.
- Testing rule: Do NOT run UI tests (`rudrasoul-jyotishUITests`). Run only unit tests (`-only-testing:rudrasoul-jyotishTests`) or build (`xcodebuild build`).
- Calculation modules (all pure, under `Services/`): `VimshottariDashaCalculator` (3 stored levels, Sookshma/Prana on demand via `subPeriods`),
  `YoginiDashaCalculator`, `CharaDashaCalculator` (Chara + Lagnamsa), `UpagrahaCalculator` (Gulika/Maandi timing),
  `JaiminiCalculator` (+`JaiminiSpecialLagnas`: karakas, arudha padas with exceptions OFF by default, Indu/Sree/Bhava/Hora/Ghati/Varnada lagnas),
  `ShashtiamsaTable` (D-60 deities, equal 0°30' parts, reversed in even signs), `KotaChakraCalculator`, `SarvatobhadraCalculator`,
  and the shared longitude helpers in `JyotishLongitude.swift`.
- `EphemerisKit` exposes `riseSetTime(of:event:after:coordinates:source:)` (Hindu rising: disc centre, no refraction) and `ayanamsaValue(at:ayanamsa:)`;
  `ChartCalculationService` uses them for sunrise/sunset, vara, and the ayanamsa DMS shown in the header.
- `ChartDetail` is stored whole as JSON (`raw_chart_json`); every field added after V1 is optional with a nil default so older rows still decode.
  Views must tolerate nil (`upagrahas`, `jaimini`, `yoginiDasha`, `charaDasha`, `lagnamsaDasha`, `kota.cells`, `vargas[].upagrahaRasis`).
- The sidebar has a `Jaimini` analysis page; the Dasha page has a system picker (Vimshottari, Yogini, Chara, Lagnamsa) and a target-date stepper.

## Implementation constraints

- Work step by step; never build all screens in one change.
- Do not rewrite existing UI during component extraction.
- Shared cross-feature UI belongs in `DesignSystem`; feature-local UI stays in
  its feature.
- Use native macOS SwiftUI controls and behaviors before custom equivalents.
- Feature code must use tokens, localized strings, and monospaced digits for
  numeric data.
- Do not invent astrological preview data. Use verified fixtures once present.
- Do not add dependencies without owner approval.

## Reference duplication audit

Repeated patterns across the reference screens include the toolbar/search area,
chart identity, analysis navigation, transit date controls, status bar, compact
chips/tiles, and dense data tables. Treat these as prospective shared APIs.
Validate each API against an actual SwiftUI consumer before extraction.

## Decisions pending

- Snapshot infrastructure is not configured. Adding a third-party snapshot
  dependency requires owner approval; an in-house approach has not been chosen.
- Localisation is deferred by owner direction; do not add translated strings
  unless the owner asks to resume localisation work.
