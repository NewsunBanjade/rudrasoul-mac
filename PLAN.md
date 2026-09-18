# Jyotish Pro implementation plan

## Working agreement

- Treat `agents.md` as the engineering authority and `html/DESIGN.md` plus the
  reference screenshots as visual guidance.
- Build native SwiftUI. Do not copy HTML, Tailwind classes, or web layout code.
- Work on one reviewable UI slice at a time.
- Preserve existing UI while extracting shared components; do not rewrite a
  working screen solely to introduce an abstraction.
- Add a shared component only after a real use establishes its requirements.

## Shared component boundaries

The reference screens repeatedly show these candidates for `DesignSystem`:

1. App/window chrome: toolbar actions, search, and status bar.
2. Chart context: chart identity header and ayanamsa/node metadata.
3. Navigation: chart-analysis sidebar sections and rows.
4. Time controls: transit date stepper and A.D./B.S. selection.
5. Compact data UI: status chip, planet chip, filter token, and metric tile.
6. Domain visuals: North/South Indian Rasi charts, lifespan timeline, SBC grid,
   and Kota mandala.

These are candidate boundaries, not permission to build every variant up front.
Feature-only views remain with their feature until a second use proves they are
shared.

## Delivery sequence

### Step 0 — Baseline and records

- Inventory the repository and visual references.
- Establish this plan, `TODO.md`, and `MEMORY.md`.
- Confirm the current app still contains only the starter screen.

### Step 1 — Project foundation

- Confirm or create the Xcode project structure required by `agents.md`.
- Add the minimal `DesignSystem` token layer using dynamic macOS system colors,
  four semantic text styles, monospaced digits, and the 8-point spacing grid.
- Add token tests or focused compile-time verification where practical.
- Keep `ContentView` visually unchanged.

### Step 2 — Library shell

- Implement the Library as the first real screen using native split-view,
  toolbar, search, and table APIs.
- Keep Library-only pieces local.
- Extract only the shell pieces already needed by more than one screen.
- Verify light/dark, English/Nepali, keyboard use, and accessibility.

### Step 3 — Chart window shell

- Add one chart window with shared chart identity, analysis navigation, and
  status bar.
- Reuse the shell without duplicating it in individual analysis screens.

### Step 4 onward — One feature per step

- Overview, chart entry, Dasha, divisional charts, strength, chakras, and other
  screens proceed individually in the phase order from `agents.md`.
- Calculation-backed UI waits for verified services and golden fixtures.

## Verification per step

- Build with strict concurrency and zero warnings.
- Run relevant tests, SwiftFormat, and SwiftLint when their configurations and
  tools are present.
- For UI work, check light/dark, English/Nepali, overflow, keyboard navigation,
  Increase Contrast, Reduce Motion, and VoiceOver descriptions.
- Record completed checks and unresolved constraints in `TODO.md` and
  `MEMORY.md`.
