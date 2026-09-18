# Jyotish Pro TODO

Update this file at the end of each implementation step. Check an item only
after its verification is complete.

## Completed — Baseline and records

- [x] Read `agents.md` completely.
- [x] Read `html/DESIGN.md`.
- [x] Inventory Swift sources, HTML references, assets, and ADRs.
- [x] Identify repeated reference UI and proposed shared boundaries.
- [x] Create `PLAN.md`, `TODO.md`, and `MEMORY.md`.
- [x] Confirm the intended first product screen with the owner.

## Completed — Project foundation

- [x] Inspect Xcode project settings, deployment target, and strict concurrency.
- [x] Keep the current filesystem-synchronised target layout without introducing
      premature package boundaries.
- [x] Create the minimal DesignSystem token layer.
- [x] Keep the existing starter view visually unchanged.
- [x] Add focused spacing and typography tests.
- [x] Build successfully under Swift 6 strict concurrency.
- [ ] Run formatting and linting (tools and repository configs are not present).

## In progress — Library shell

- [x] Confirm Library as the first product screen with the owner.
- [x] Define fixture-backed display data; do not invent chart records.
- [x] Implement the screen model and native split-view/table shell.
- [ ] Add model, accessibility, and snapshot coverage.
  - [x] Add empty-fixture model coverage.
  - [x] Add native accessibility labels and plain English strings.
  - [ ] Add Library snapshot infrastructure and the required appearance/locale
        matrix once a snapshot approach is approved.

## Completed — Single Window & Unified Navigation

- [x] Unified Library and Analysis navigation into a single sidebar menu:
  - `Library` section: `All Charts`, `Recent`.
  - `Chart` section: `Overview`, `Divisional Charts`, `Planets & Houses`, `Strength`, `Ashtakavarga`, `Dasha`, `Nakshatra`, `Yogas & Doshas`.
  - `Chakras` section: `Sarvatobhadra`, `Kota`.
  - `Tools` section: `Progression & Transit`, `Notes & Predictions`.
- [x] Eliminated secondary window opening (`WindowGroup` removed); selecting or opening charts navigates in-place within the same window.
- [x] Added quick active chart switcher menu in the navigation bar.
- [x] Added test coverage for in-place chart selection and navigation.

## Completed — UI Pages & Analysis Screens

- [x] Implemented `NewChartSheet`:
  - 2-column modal layout with subject details, gender, A.D. and B.S. date switcher with live calendar conversion callout.
  - Time accuracy, atlas city lookup, coordinates, timezone selection, DST and LMT historical toggles.
  - Astrological calculation parameters (Ayanamsa, True/Mean nodes, house system, chart style, practitioner notes).
  - Integrated with `LibraryScreen` via `+ New Chart` toolbar button (`⌘N`).
- [x] Implemented `OverviewView`:
  - Top status metrics, chart style picker (North Indian diamond / South Indian grid).
  - Dual Kundali (D-1 Rasi and D-9 Navamsha) with Canvas rendering.
  - Vimshottari Mahadasha continuum strip.
  - Planetary positions & dignities table.
- [x] Implemented `DivisionalChartsView`:
  - Shodashavarga selector covering all 16 classical divisions (D-1 to D-60).
  - Varga Kundali canvas and planet placement table with Vargottama indicators.
- [x] Implemented `PlanetsAndHousesView`:
  - Detailed planetary positions, retrogrades, speeds, nakshatra padas, dignities, and chara karakas.
  - Bhava Chalit house cusps, sign lords, and occupant planet tables.
- [x] Implemented `StrengthView`:
  - Sixfold Shadbala breakdown (Sthana, Dik, Kala, Cheshta, Naisargika, Drik bala).
  - Visual Rupa threshold meters with 1.00 Rupa required line and ranking cards.
- [x] Implemented `AshtakavargaView`:
  - Sarvashtakavarga (SAV) 12-sign cards with >= 28 bindu threshold indicators.
  - Individual Bhinnashtakavarga (BAV) planetary bindu rows.
- [x] Implemented `DashaView`:
  - Target date stepper with jump and now controls.
  - Lifespan Mahadasha Continuum strip (120-year cycle).
  - Hierarchical 5-level dasha table (MD > AD > PD > SD > PrD) with status and roles.
  - Dedicated Dasha Inspector with active lord dignity and predictive indications.
- [x] Implemented `NakshatraView`:
  - 27 Nakshatras table with rulers, deities, ganas, and resident natal planets.
- [x] Implemented `YogasAndDoshasView`:
  - Classical Yogas catalog (Pancha Mahapurusha, Raja Yoga, Dhana Yoga, etc.) with textual citations.
- [x] Implemented `SarvatobhadraView`:
  - 9x9 Sarvatobhadra mandala grid, 28 nakshatras with Abhijit, vowels, and vedha ray indications.
- [x] Implemented `KotaView`:
  - 4 concentric fortress zones (Stambha, Madhya, Prakara, Bahya), Kota Swami/Pala, and Pravesha/Nirgama paths.
- [x] Implemented `ProgressionTransitView`:
  - Transit date stepper, Gochara evaluation, and natal vs transit position comparisons.
- [x] Implemented `NotesPredictionsView`:
  - Clinical case notes editor with autosave badge, prediction log with status tracking.
- [x] Implemented `SettingsScreen`:
  - Native macOS Settings scene for calculation defaults, display options, and ephemeris status.
- [x] Implemented shared DesignSystem components:
  - `NorthIndianChartCanvas` and `SouthIndianChartCanvas`.
  - `TransitDateStepper` and `MetricTile`.
- [x] Verified unit tests pass cleanly in under 3s without running slow UI tests.

## Completed — Swiss Ephemeris foundation

- [x] Vendor Swiss Ephemeris 2.10.03 C runtime with licence and provenance.
- [x] Add an actor-isolated `EphemerisKit` API for Julian days, sidereal
      positions, and houses.
- [x] Bundle Swiss planetary and lunar data for 1800–2399.
- [x] Add J2000 Lahiri reference fixtures and integration/thread-safety tests.
- [x] Link the local package into the macOS application and build successfully.

## Completed — SQLite Persistence Layer

- [x] Implemented native SQLite engine (`rudrasoul-jyotish/Persistence/`):
  - `SQLiteDatabase`: Nonisolated engine with connection management, WAL mode, normal synchronous, foreign keys enabled, transactions, and SQLite online backup API.
  - `SQLiteStatement`: Prepared statement wrapper with typed parameter binding and column decoding (UUID, Date, String, Int, Double, Bool, Data).
  - `SQLiteError`: Typed errors with localized error descriptions.
  - `PersistenceLogger`: Unified OS logging subsystem (`com.rudrasoul.jyotish`).
- [x] Implemented versioned migration system (`Migration`, `MigrationRunner`, `MigrationV1_InitialSchema`):
  - Tracked via `PRAGMA user_version`.
  - Schema V1 creates `charts`, `chart_notes`, and `chart_predictions` tables with cascading foreign keys.
  - Indexed columns for fast query filtering (`idx_charts_name`, `idx_charts_birth_date`, `idx_charts_lagna_rasi`, `idx_charts_moon_nakshatra`, `idx_charts_engine_version`, `idx_charts_updated_at`, `idx_chart_notes_chart_id`, `idx_chart_predictions_chart_id`).
- [x] Implemented repository layer (`ChartRepository`, `SQLiteChartRepository`):
  - CRUD operations: `saveChart`, `fetchChartDetail`, `fetchAllCharts`, `searchCharts`, `deleteChart`, `countCharts`.
  - Automatic seeding of verified golden chart fixtures (Tagore & Gandhi) when library is empty.
  - SQLite backup and restore operations for database import/export.
- [x] Integrated persistence with `ChartStore`:
  - `ChartStore` reloads on launch from `SQLiteChartRepository.shared`.
  - Chart creation and edits in `NewChartSheet` persist to SQLite disk storage.
  - Chart deletions cascade and remove from disk storage.
  - Added delete capability to library table context menu.
- [x] Added comprehensive unit tests in `rudrasoul-jyotishTests/PersistenceTests.swift`:
  - `SQLiteDatabaseTests`: in-memory database, parameter bindings, transactions rollback, user_version tracking.
  - `MigrationTests`: schema creation, indices, and migration idempotency.
  - `SQLiteChartRepositoryTests`: initialization, seeding, save/fetch fidelity, search, cascading deletes, database export & restore.
  - All 19 unit tests pass in 1.56s.

## Blocked or deferred

- SwiftFormat and SwiftLint plus their repository configs are not present, so
  their quality gates cannot run yet.
- The modular package structure remains deferred until real domain boundaries
  exist; the current app uses Xcode filesystem-synchronised groups.
- No astrology calculation is part of the current UI-planning step, so no
  golden fixture is changed or required yet.
- Trusted chart fixtures do not exist yet. The Library uses an explicit empty
  fixture and does not reproduce the fictional records from the visual reference.
- Localisation is deferred by owner direction; current feature work uses English only.
