# AGENTS.md — Jyotish Pro (macOS)

This file tells AI coding agents and human contributors how this project is built, what rules they must follow, and what "done" means. Read it fully before making any change.

---

## 1. Project overview

Jyotish Pro is a professional Vedic astrology (Jyotish) application for macOS, built natively with Swift and SwiftUI.

**Users** are practising astrologers. They verify every number, so a wrong degree or date is a critical bug, not a cosmetic one.

**Core features**
- Chart library with advanced astrological filters
- New chart entry, with A.D. and Bikram Sambat dates and LMT for historical charts
- Vimshottari dasha, to five levels
- Divisional charts, Shadbala, and Ashtakavarga
- Sarvatobhadra and Kota Chakra, with transits
- Practitioner notes, and printing/export

**Market:** Nepal first, then international. English and Nepali (Devanagari) are both first-class.

**Design source:** Google Stitch screens in `Design/`. They are a visual reference only. Never port Stitch HTML or CSS.

---

## 2. Guiding principles

1. **Correctness before features.** A new screen never ships on top of an unverified calculation.
2. **The calculation core is pure.** Astrology logic has no UI, database, or C dependencies, and is fully unit-tested.
3. **Native first.** Use standard macOS controls and behaviour before building anything custom.
4. **One source of truth.** One chart header, one date stepper, one status bar, one token set.
5. **Small, reviewable changes.** Each change does one thing and includes its tests.
6. **Explicit over clever.** Readable code beats terse code. Name astrological concepts by their Jyotish terms.
7. **Stored input, derived output.** Persist what the user entered, and recompute everything else.

---

## 3. Technology baseline

| Area | Decision |
|---|---|
| Language | Swift 6, strict concurrency checking enabled |
| Minimum OS | macOS 14 (Sonoma) |
| Tooling | Current stable Xcode |
| UI | SwiftUI; AppKit only when SwiftUI cannot do the job, wrapped and isolated |
| State | Observation framework (`@Observable`) |
| Concurrency | Swift concurrency: async/await, actors, `Sendable` |
| Ephemeris | Swiss Ephemeris (C), wrapped in its own package target |
| Persistence | GRDB (SQLite) with versioned migrations |
| Graphics | SwiftUI `Canvas` for charts, chakras, and timelines |
| Tests | Swift Testing for logic; snapshot tests for UI |
| Formatting and linting | SwiftFormat and SwiftLint; configs live in the repository root |
| Localisation | String Catalogs (en, ne) |
| Dependencies | Swift Package Manager only; every new dependency needs owner approval |

Do not add CocoaPods, Carthage, Combine-based architectures, third-party UI kits, or reactive frameworks.

---

## 4. Repository layout

```
JyotishPro/
├── AGENTS.md
├── Design/                    Stitch reference screens (light + dark), token spec
├── Docs/
│   ├── ADR/                   Architecture Decision Records
│   ├── Astrology/             Rule references with classical sources
│   └── Fixtures/              Reference outputs from verification software
├── App/                       App target: entry point, scenes, menus, composition root
└── Packages/JyotishKit/
    ├── Sources/
    │   ├── CSwissEph/         Vendored C library + ephemeris data files
    │   ├── EphemerisKit/      Swift wrapper behind a protocol
    │   ├── JyotishCore/       Pure domain: models and all calculations
    │   ├── Persistence/       GRDB database, migrations, repositories
    │   ├── Services/          Orchestration between core, ephemeris and storage
    │   ├── DesignSystem/      Tokens and shared components
    │   └── Features/          One folder per screen (Library, NewChart, Dasha, …)
    └── Tests/
        ├── JyotishCoreTests/
        ├── EphemerisKitTests/
        ├── PersistenceTests/
        └── FeatureSnapshotTests/
```

---

## 5. Architecture rules

### 5.1 Dependency direction (enforced)

```
App → Features → Services → JyotishCore
                      ├──→ EphemerisKit → CSwissEph
                      └──→ Persistence
Features → DesignSystem
```

Import rules:
- `JyotishCore` imports only Foundation. It never imports SwiftUI, GRDB, or `CSwissEph`.
- `DesignSystem` never imports `Services` or `Persistence`.
- A Feature never imports another Feature. Shared UI moves into `DesignSystem`, and shared logic moves into `Services` or `JyotishCore`.
- Only `App` knows the concrete implementations. Every other layer depends on protocols.

### 5.2 Module responsibilities

- **JyotishCore:** grahas, rasis, nakshatras, vargas, dashas, strengths, yogas, chakras, calendars, and time conversion. All calculation code is deterministic and has no side effects.
- **EphemerisKit:** converts Julian Day and settings into positions and houses. Nothing else. It is the only place that touches C.
- **Persistence:** schema, migrations, queries, and repositories. No astrology logic.
- **Services:** combine the core, ephemeris, and storage into use cases ("compute chart", "filter library", "dasha tree at date"). This layer handles caching.
- **DesignSystem:** colours, typography, spacing, icons, and reusable views.
- **Features:** screens. Each screen has a view layer and one `@Observable` model.
- **App:** scenes, windows, menus, settings, dependency wiring.

### 5.3 Feature structure

Each feature folder contains:
- **Screen views:** these only render state and forward user actions.
- **One observable model per screen:** it owns screen state, calls services, and exposes ready-to-display values.
- **Feature-local subviews:** anything reused elsewhere moves to `DesignSystem`.
- **Previews:** these use fake services and fixture data, never live ephemeris.

Views never call repositories or the ephemeris directly. Models never import AppKit.

### 5.4 Architecture Decision Records

Any decision that changes structure, adds a dependency, changes the schema strategy, or changes a calculation convention needs an ADR in `Docs/ADR/`. An ADR states the context, the decision, the alternatives considered, and the consequences.

---

## 6. State, data flow, and windows

- **Data flow is one-way:** a user action goes to the model, the model calls a service, the service returns new state, and the view re-renders.
- **Dependency injection:** dependencies are passed at initialisation or through the SwiftUI environment from the composition root. No singletons except the app environment itself.
- **Window structure:** the Library is the main window. Each opened chart gets its own window, identified by chart ID, which supports side-by-side comparison.
- **Standard macOS patterns:**
  - Split view navigation with the inspector for right panels
  - Toolbar and searchable for search
  - Sheets for creation and edit dialogs
  - Popovers for filters
  - A Settings scene for preferences
- **Keyboard support:** every primary action has a menu command and a keyboard shortcut.
- **State restoration:** window state (selected screen, focus date, inspector visibility) is restored on relaunch.

---

## 7. Concurrency rules

- Strict concurrency stays on, and there are no warnings in main.
- The Swiss Ephemeris wrapper is an **actor**, because the C library is not thread-safe. No other code may call the C functions.
- Heavy calculations (full chart, dasha tree, library-wide filter indexing) run off the main actor. UI models are main-actor isolated.
- Long work is cancellable. Changing the focus date cancels the previous calculation.
- `@unchecked Sendable` and `nonisolated(unsafe)` are not allowed without an ADR.

---

## 8. Astrological correctness (highest priority)

### 8.1 Verification

- Every calculation has **golden fixture tests** against trusted reference output, stored in `Docs/Fixtures/` with the source and settings recorded.
- **Required fixtures:**
  - Rabindranath Tagore (pre-1906 LMT)
  - Mahatma Gandhi
  - One modern Nepal chart (NST, recent B.S. date)
  - One southern-hemisphere chart
  - One chart near a nakshatra boundary
  - One chart near a sign ingress
- **Tolerances:**
  - Planetary longitudes: ±1 arcsecond against Swiss Ephemeris reference values
  - Ascendant: ±2 arcseconds
  - Dasha boundaries: ±1 minute with the same year length
  - B.S. dates: exact
- A change to any calculation must update the fixtures deliberately, never automatically, and explain why in the change description.

### 8.2 Conventions (one place, documented)

- **Time:** birth data is stored as local civil date and time, a time-zone rule (IANA zone or LMT from longitude), and coordinates. Conversion to Julian Day happens in exactly one function.
- **LMT:** used by default for historical dates before standard time was adopted in that place. The user can override it.
- **Ayanamsa:** Lahiri is the default. The ayanamsa is always stored with the chart and always shown with a label.
- **Nodes:** True or Mean is a chart setting that is stored and displayed.
- **Vimshottari:**
  - The first mahadasha comes from the Moon's nakshatra lord.
  - Every sub-period list starts with its parent lord and continues in the fixed order.
  - Year length is a setting (solar 365.2422 or 360), stored with the chart.
- **Bikram Sambat:** use verified tables where they exist. For dates outside those tables, derive months from sidereal solar ingress, and test against published Nepali patros.
- **Relationships and strengths:** natural, temporal, and compound relationships, Shadbala thresholds, avasthas, and similar tables live in `JyotishCore` as data with a classical source cited next to them.

### 8.3 Documentation of rules

Every non-trivial astrological rule has a doc comment that states the rule in plain words and cites its classical source (e.g. BPHS chapter). If sources disagree, the chosen variant is a setting, or an ADR records the choice.

### 8.4 Never

- Never invent astrological data for previews or mocks. Preview data comes from fixtures.
- Never round values before the display layer.
- Never compute the same quantity in two places.

---

## 9. Persistence rules

- **Stored:** user input (birth data, settings, notes, tags, folders) is persisted.
- **Derived:** derived values (positions, lagna, nakshatra, current dasha) are cached in indexed columns only to support filtering, and every cached row records the **engine version**.
- **Engine version changes:** a change of engine version triggers background recomputation.
- **Migrations:** all schema changes go through numbered migrations. A migration is never edited after it ships.
- **Testing:** each migration is tested on a copy of the previous schema with sample data.
- **Import and export:** support the app's own format and common astrology exchange formats. Imports never write partial records.
- **Backups:** the user's library can be exported and restored.

---

## 10. UI and design system rules

### 10.1 Tokens only

- No hard-coded colours, font sizes, or spacing in feature code. Everything comes from `DesignSystem`.
- **Colours** are defined in the asset catalog with light and dark variants:
  - One accent (deep indigo)
  - Neutral greys
  - Semantic colours: natal, transit, malefic, benefic, warning
- **Text styles:** four only (title, section, body, caption), in sentence case. No decorative uppercase labels.
- **Numbers:** dates, times, degrees, durations, and scores always use monospaced digits.
- **Spacing:** 8-point grid.

### 10.2 Shared components (build once, reuse everywhere)

- **Header and time:** chart header, transit date stepper, status bar.
- **Chips and tiles:** status chip, planet chip, filter token, metric tile.
- **Charts:** North Indian and South Indian Rasi charts, lifespan timeline, SBC grid, Kota mandala.

A second variant of any of these components needs design approval.

### 10.3 Native behaviour

- Use standard macOS selection, focus rings, context menus, drag and drop, undo/redo, printing, and full keyboard navigation.
- Content never overflows its container, and the status bar is never overlapped.
- Every screen supports Light and Dark mode, Increase Contrast, Reduce Motion, and Dynamic Type where macOS allows it.
- **Accessibility:** every chart and chakra has VoiceOver labels describing its content ("Mars retrograde in Anuradha, Madhya zone").

### 10.4 Avoid

- Solid blue pills and badges on everything, cards inside cards, full-width primary buttons, and web-style dashboards.
- Showing two scripts (IAST and Devanagari) at once in dense views.

---

## 11. Localisation and Nepal specifics

- Every user-facing string lives in the String Catalog. There are no string literals in views.
- **Nepali:** the UI is fully translated, with an option for Devanagari numerals. Astrological terms use the standard Nepali and Sanskrit forms, reviewed by a practising jyotishi.
- **Dates:** the A.D./B.S. toggle is available everywhere a date is shown. Nepal Standard Time (UTC+05:45) and historical offsets are handled correctly.
- **Fonts:** Devanagari uses a system font sized to match SF Pro visually.
- **Formatting:** always use locale-aware formatters, never manual string formatting.

---

## 12. Code style

- SwiftFormat and SwiftLint pass with zero warnings before commit.
- **Access control:** the default is `internal`. `public` only for intentional module API, `private` wherever possible.
- **Types:** value types by default. Classes only for observable models, actors, and wrappers around reference resources.
- **Force unwraps and `try!`:** not allowed outside tests.
- **Names:** Jyotish terms for concepts (`Graha`, `Nakshatra`, `Mahadasha`), Swift conventions for everything else. No abbreviations except the established ones (MD, AD, PD, SD, PrD) used as display strings.
- **Units:** angles are stored in decimal degrees and converted to DMS only for display. Angles, durations, and Julian Days get distinct types so they cannot be mixed up.
- **Size limits:** a file stays under about 400 lines, and a function under about 40 lines. Split when these are exceeded.
- **Comments:** comments explain *why* and cite sources. Code explains *what*.

---

## 13. Error handling and logging

- Errors are typed per module and converted to user-readable messages at the feature layer.
- The UI never crashes on bad input. Invalid fields show inline validation.
- **Logging:** use unified logging (`Logger`) with a subsystem and a category per module. Never use `print`.
- **Privacy:** never log birth data, names, or notes.

---

## 14. Testing and quality gates

| Layer | Required tests |
|---|---|
| JyotishCore | Unit tests plus golden fixtures for every public calculation |
| EphemerisKit | Reference position tests; thread-safety test |
| Persistence | Repository tests; migration tests |
| Services | Tests using fake ephemeris and in-memory database |
| Features | Model tests; snapshot tests of each screen in light, dark, English, and Nepali |

- **Coverage targets:** JyotishCore at least 90%, Services at least 80%. Coverage never drops in a change.
- **Performance budgets** (measured on the baseline Mac, with regressions tested):
  - Full chart computation: under 50 ms
  - 5-level dasha tree: under 20 ms
  - Library filter across 10,000 charts: under 150 ms
  - App launch to usable library: under 1 second
- **UI checks:** each release candidate is checked manually against the Stitch references for layout, overflow, and alignment.

---

## 15. Security, privacy, and licensing

- Birth data is personal data. It is stored locally by default. Any sync or cloud feature needs explicit user consent and an ADR.
- No analytics or telemetry without opt-in.
- The app runs sandboxed with hardened runtime, and is distributed notarized.
- **Swiss Ephemeris is dual-licensed (AGPL or commercial).** The commercial licence must be in place before any closed-source release. Do not add other GPL/AGPL code.
- Third-party licences are listed in the About window.

---

## 16. Workflow for agents

### Before writing code
1. Read this file and any ADRs relevant to the area.
2. Restate the task, the affected modules, and the plan in a few lines.
3. If the task touches a calculation, identify the fixture that will prove it correct.
4. If requirements are ambiguous or conflict with this file, **stop and ask**.

### While working
- Change only what the task requires. No drive-by refactors.
- Follow the dependency rules. If a change seems to need a forbidden import, the design is wrong. Ask.
- Add or update tests in the same change.
- Update the String Catalog, previews, and docs affected by the change.

### Definition of done
- Build succeeds with zero warnings under strict concurrency.
- All tests pass, including golden fixtures and snapshots.
- SwiftFormat and SwiftLint are clean.
- Light, dark, English, and Nepali are verified for UI changes.
- No hard-coded colours, sizes, or strings.
- The change description states what changed, why, how it was verified, and any fixture updates.

### Commits
- Conventional style: `feat(dasha): …`, `fix(core): …`, `refactor(design): …`, `test(fixtures): …`, `docs(adr): …`.
- One logical change per commit.

### Never
- Never modify golden fixtures just to make tests pass.
- Never edit a shipped migration.
- Never bypass the ephemeris actor.
- Never add a dependency without approval.
- Never commit ephemeris licence keys, signing credentials, or user data.

---

## 17. Build and test commands

| Task | Command |
|---|---|
| Build app | `xcodebuild -scheme JyotishPro -destination 'platform=macOS' build` |
| Run all tests | `xcodebuild -scheme JyotishPro -destination 'platform=macOS' test` |
| Test packages only | `swift test --package-path Packages/JyotishKit` |
| Format | `swiftformat .` |
| Lint | `swiftlint --strict` |

---

## 18. Delivery phases

1. **Foundation:** JyotishCore, EphemerisKit, golden fixtures, CI.
2. **Library:** persistence, chart list, search and filters.
3. **Chart entry:** New Chart sheet, atlas, LMT, B.S. conversion.
4. **Shell:** DesignSystem components, chart window, header, status bar.
5. **Analysis screens:** Overview, Dasha, Divisional, Strength, Ashtakavarga.
6. **Chakras:** Sarvatobhadra, Kota, Tara, Sudarshana, with transits.
7. **Polish:** Nepali localisation, accessibility, print/export, performance.
8. **Release:** licensing, notarization, distribution, backup/restore.

A phase starts only when the previous phase's quality gates pass.

---

## 19. Glossary

| Term | Meaning |
|---|---|
| Graha | Planet (including Rahu and Ketu) |
| Rasi | Zodiac sign |
| Nakshatra | Lunar mansion (27, or 28 with Abhijit) |
| Lagna | Ascendant |
| MD / AD / PD / SD / PrD | Mahadasha / Antardasha / Pratyantardasha / Sookshma / Prana dasha |
| Varga | Divisional chart (D-1, D-9, …) |
| Ayanamsa | Sidereal offset (default Lahiri) |
| LMT | Local Mean Time |
| NST | Nepal Standard Time (UTC+05:45) |
| B.S. | Bikram Sambat calendar |
| SBC | Sarvatobhadra Chakra |
| Vedha | Obstruction or aspect ray in the SBC |
| Kota Chakra | Fortress chakra: Stambha, Madhya, Prakara, Bahya |
| Pravesha / Nirgama | Entering / exiting movement in the Kota Chakra |
| Golden fixture | Verified reference output used as a test oracle |
