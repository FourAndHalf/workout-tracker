---
name: Pearl Ledger · Coral
colors:
  surface: '#F4F4F5'
  surface-dim: '#DCDCDF'
  surface-bright: '#FAFAFB'
  surface-container-lowest: '#FFFFFF'
  surface-container-low: '#F1F1F3'
  surface-container: '#ECECEE'
  surface-container-high: '#E6E6E9'
  surface-container-highest: '#E0E0E3'
  on-surface: '#1C1C1E'
  on-surface-variant: '#626267'
  inverse-surface: '#2A2A2D'
  inverse-on-surface: '#F2F2F3'
  outline: '#A1A1A6'
  outline-variant: '#DADADD'
  surface-tint: '#2A2A2D'
  primary: '#2A2A2D'
  on-primary: '#FFFFFF'
  primary-container: '#3A3A3D'
  on-primary-container: '#F2F2F3'
  inverse-primary: '#C8C8CC'
  secondary: '#5E5E63'
  on-secondary: '#FFFFFF'
  secondary-container: '#E4E4E7'
  on-secondary-container: '#2A2A2D'
  tertiary: '#7A6A47'
  on-tertiary: '#FFFFFF'
  tertiary-container: '#EDE6D6'
  on-tertiary-container: '#4A3F28'
  error: '#B33A35'
  on-error: '#FFFFFF'
  error-container: '#F9DEDC'
  on-error-container: '#5C1612'
  primary-fixed: '#E3E3E6'
  primary-fixed-dim: '#C8C8CC'
  on-primary-fixed: '#1C1C1E'
  on-primary-fixed-variant: '#46464A'
  secondary-fixed: '#E4E4E7'
  secondary-fixed-dim: '#C9C9CD'
  on-secondary-fixed: '#1C1C1E'
  on-secondary-fixed-variant: '#46464A'
  tertiary-fixed: '#EDE6D6'
  tertiary-fixed-dim: '#D6CBB2'
  on-tertiary-fixed: '#2B2415'
  on-tertiary-fixed-variant: '#5A4E33'
  background: '#E8E8EA'
  on-background: '#1C1C1E'
  surface-variant: '#E0E0E3'
  positive: '#23784A'
  positive-container: '#DDF0E4'
  negative: '#B33A35'
  negative-container: '#F9DEDC'
  warning: '#8A5A0F'
  warning-container: '#F6E7CC'
  info: '#3F5F80'
  info-container: '#DFE8F1'
  accent: '#E4572E'
  accent-text: '#B83A18'
  accent-fill: '#CC4722'
  accent-fill-end: '#B23514'
  on-accent: '#FFFFFF'
  accent-container: '#FCE7DF'
typography:
  headline-xl:
    fontFamily: JetBrains Mono
    fontSize: 30px
    fontWeight: '500'
    lineHeight: 38px
    letterSpacing: -0.03em
  headline-xl-mobile:
    fontFamily: JetBrains Mono
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 28px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: JetBrains Mono
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 24px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: JetBrains Mono
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: 0em
  body-md:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 19px
    letterSpacing: 0em
  body-sm:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 15px
    letterSpacing: 0em
  metric-hero:
    fontFamily: JetBrains Mono
    fontSize: 34px
    fontWeight: '500'
    lineHeight: 40px
    letterSpacing: -0.045em
  metric-hero-mobile:
    fontFamily: JetBrains Mono
    fontSize: 32px
    fontWeight: '500'
    lineHeight: 38px
    letterSpacing: -0.045em
  metric-card:
    fontFamily: JetBrains Mono
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 24px
    letterSpacing: -0.03em
  metric-table:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: -0.01em
  metric-delta:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 12px
    letterSpacing: 0em
  ledger-mono:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0em
  label-uppercase:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 12px
    letterSpacing: 0.08em
  label-regular:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0em
rounded:
  sm: 8px
  md: 14px
  lg: 20px
  xl: 28px
  full: 9999px
spacing:
  gutter: 0.75rem
  gutter-mobile: 0.625rem
  margin: 1.5rem
  margin-mobile: 1rem
  card-padding: 1.25rem
  card-padding-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

# Fitness Tracker design system

This is the design system for the whole app. It covers Home, Programs, the
live workout, Explore, Progress, Nutrition and the home-screen widgets. The
tokens above are the light theme; §2 lists the dark theme. Every token is
implemented in `lib/core/theme/app_colors.dart` (`context.colors`), and the
text styles in `lib/core/theme/app_theme.dart` (`AppText`).

**One-line summary:** calm pearl or graphite surfaces, numbers set like a
well-kept training log, and one coral accent that always means *this is what
you're doing now*.

## 1. Brand & style

- **Tone:** steady, precise, encouraging without hype. A training log you
  trust, not a game. Numbers are stated plainly: `4 × 8–12`, `62.5 kg`,
  `5:30 /km`.
- **Aesthetic:** soft pearl (light) or graphite (dark) surfaces, rounded
  modules in a bento layout, monospaced figures, generous whitespace.
- **Hierarchy comes from tone, type and space.** Colour is spent sparingly:
  - **coral** for focus and the one main action;
  - **semantic colours** for meaning (done, missed, warning);
  - **champagne** for rare milestones.
- **Avoid:** neon or rainbow gradients, confetti and badges-for-everything
  gamification, emoji in data, heavy drop shadows, decorative illustrations
  inside data areas, and colour used as a large background fill.

## 2. Colors

### Neutral foundation
| Role | Light | Dark | Use |
|---|---|---|---|
| Canvas (`background`) | `#E8E8EA` | `#0F0F11` | Page behind everything |
| Inner panel (`surface`) | `#ECECEE` | `#1C1C1F` | A module inside a module, input tracks |
| Module (`card`) | `#F1F1F3` | `#161618` | Cards and panels |
| Raised control (`raised`) | `#FFFFFF` | `#232326` | Icon buttons, segmented thumbs, search field |
| Hairline (`border` / `divider`) | `#DADADD` / `#E0E0E3` | `#2C2C30` | Borders, dividers |
| Ink (`textPrimary`) | `#1C1C1E` | `#ECECEE` | Titles, values |
| Muted ink (`textSecondary`) | `#626267` | `#A0A0A6` | Labels, captions, axis text (≥4.5:1 on modules) |
| Faint ink (`textMuted`) | `#6E6E73` | `#8E8E94` | Micro-labels, metadata |
| Charcoal anchor (`primary`) | `#2A2A2D` | `#ECECEE` (inverts) | Structure: active nav pill, secondary-emphasis buttons, non-current chart bars |
| Tracks (`track` / `barMuted`) | `#D4D4D8` / `#C9C9CD` | `#2C2C30` / `#3A3A3F` | Progress tracks, inactive bars |

### Coral accent: focus and the main action

Coral is the app's single accent. It always means **this is what you're
doing now**: the selected item, the next or current workout, live progress,
or the one main action on a screen.

| Token | Light | Dark | Use |
|---|---|---|---|
| `accent` | `#E4572E` | `#FF7A59` | **Graphics only:** a selected highlight, the current bar, meters, borders, glows, the body-figure highlight |
| `accentText` | `#B83A18` | `#FF7A59` | **Coral text and small icons** on any surface |
| `accentFill` → `accentFillEnd` | `#CC4722` → `#B23514` | `#FF7A59` → `#F0533A` | Gradient for filled coral controls (top-left to bottom-right) |
| `onAccent` | `#FFFFFF` | `#161618` | Text and icons on the filled gradient |
| `accentContainer` | `#FCE7DF` | `#2A1812` | Soft tint behind a selected row or an opened card |

**Measured contrast.** Never pair coral differently from this table without
re-measuring.

| Pairing | Light | Dark | Requirement |
|---|---|---|---|
| `accentText` on canvas / module / raised | 4.69 / 4.87 / 5.74 | 7.46 / 7.04 / 6.11 | Text needs 4.5:1 |
| `onAccent` on `accentFill` / `accentFillEnd` | 4.68 / 6.15 | 7.04 / 5.17 | Text needs 4.5:1 |
| Ink on `accentContainer` | 14.29 | 14.38 | 4.5:1 |
| `accentText` on `accentContainer` | 4.82 | 6.61 | 4.5:1 |
| `accent` graphic vs its module | 3.27 | 7.04 | Graphics need 3:1 |

Two traps:
- Light `accent` (`#E4572E`) is too pale for small text, at 3.27:1. Use `accentText`.
- In dark mode, white on coral fails at 2.57:1. That's why `onAccent` is dark ink there.

**Where coral goes:**
- **The one main action** on a screen, as a filled gradient pill with a soft coral
  shadow: *Start workout*, *Use this split*, the widget's *Start* button.
  Only one per screen. Actions repeated down a list, such as *Log set*, use
  the neutral primary button.
- **Selection:**
  - selected filter and picker chips (muscle chips, days-per-week, track switcher);
  - the selected row in a list (an `accentContainer` tint plus a 70%-opacity `accent` border);
  - the selected part on the body figure.
- **Now and next:**
  - the next workout's card border on Programs and Home;
  - the running set's countdown ring;
  - the live session progress bar;
  - the current period's bar in a chart.
- **Recommendation markers:** an outlined *TOP PICK* pill in `accentText` and
  focus meters (3 bars in `accent`).
- **Inline links** inside body copy, in `accentText`.

**Where coral never goes:**
- **Large backgrounds.** A screen or a whole module is never coral. The only
  tinted areas allowed are an `accentContainer` row or an opened card.
- **Meaning.** Coral never signals good or bad. Errors and losses use
  `error` plus a glyph and words. Coral and dark `error` are only 1.18:1
  apart, so never put them side by side and never rely on hue alone.
- **Navigation chrome.** The bottom bar's active item stays charcoal: navigation
  is structure, not focus.
- **Two main actions.** At most one filled coral button per screen. A
  selected chip in a filter row is the only other filled coral allowed.
  Everything else stays small: text, borders, rings, meters.

### Champagne: milestones only
`tertiary` `#7A6A47` (text) and `#EDE6D6` (container) in light, `#CDBB92` and
`#2B2619` in dark. Use it for rare achievements: the streak milestone module
and a completed program block. At most one champagne element per screen, and
never touching coral.

### Semantic colours (meaning only)
| Role | Light text / container | Dark text / container | Use |
|---|---|---|---|
| Positive (`success`) | `#23784A` / `#DDF0E4` | `#5BBF86` / `#16291E` | Done badges, completed sets ✓, new personal records ▲ |
| Negative (`error`) | `#B33A35` / `#F9DEDC` | `#E5726B` / `#331A18` | Failed saves, destructive actions (clear data), lower records ▼ |
| Warning | `#8A5A0F` / `#F6E7CC` | `#D9A54A` / `#2E2414` | *Review* flags on program days, the *Advanced* split level, paused sessions |
| Info | `#3F5F80` / `#DFE8F1` | `#8FB0D3` / `#1A2430` | Neutral notices, the *Intermediate* split level |

- Pair colour with a glyph or a word (`▲ 5 kg`, `Done ✓`). Meaning never
  depends on colour alone.

### Block-type tones (workout plans)
These are small badges on block cards, never fills. The superset, tri-set,
giant-set and drop-set badges reuse the info, muted, champagne and warning
tones on purpose, so a block type reads at a glance without adding new hues.

| Block | Token | Light | Dark |
|---|---|---|---|
| Straight | `straightBlock` | `#626267` | `#A0A0A6` |
| Superset | `supersetBlock` | `#3F5F80` | `#8FB0D3` |
| Tri-set | `triSetBlock` | `#5E5E63` | `#A0A0A6` |
| Giant set | `giantSetBlock` | `#7A6A47` | `#CDBB92` |
| Drop set | `dropSetBlock` | `#8A5A0F` | `#D9A54A` |
| Rest-pause | `restPauseBlock` | `#23784A` | `#5BBF86` |

## 3. Typography

One family: **JetBrains Mono** (OFL), bundled at 400/500/600 so the app works
offline. Fixed-width figures line up in set tables without extra work.

| Style | Size / line | Weight | Use |
|---|---|---|---|
| `headline-xl-mobile` | 22 / 28 | 500 | Tab titles (`DayAppBar`) |
| Screen hero title | 28–30 / 1.1 | 600, −0.5 tracking | Explore muscle name, split name |
| `headline-md` / `titleMedium` | 14–16 | 600 | Card titles, exercise names |
| `body-md` | 13 / 19 | 400 | Body copy, cues, steps |
| `body-sm` | 11 / 15 | 400 | Captions, metadata |
| `metric-hero` | 32 / 38 | 500, −0.045em | Elapsed time, big stats |
| `metric-card` | 18 / 24 | 500 | KPI values, stepper values |
| `metric-table` | 13 / 18 | 500, tabular | Set rows, `4 × 8–12`, pace |
| `label-uppercase` | 10 / 12 | 600, +0.08em | Column headers, status pills |
| **Micro-label** | 9–12 | 600, +0.22em, uppercase | Eyebrows and tags: `02 / 14 · DELTOID`, `FRONT`, `5 PICKS · GYM`, `INTERMEDIATE` |

- Hierarchy comes from size and weight. Avoid 700 and heavier.
- Sentence case by default. Uppercase only for micro-labels and status pills.
- Formats:
  - weights: `62.5 kg`
  - sets × reps: `4 × 8–12` (true × and en dash)
  - time: `27:30`
  - pace: `5:30 /km`
  - distance: `400 m` below 1 km, `7.5 km` above
- Micro-labels use `MicroLabel` (`lib/core/widgets/accent.dart`). Don't
  re-create the tracking by hand.

## 4. Layout & spacing

- **Grid:** 4 / 8 px scale.
- **Phone (primary target):** 16 px side margins, 16 px card padding, 12 px
  between modules, touch targets at least 44 × 44 px, list rows 56 px.
- **Tab pages:** `DayAppBar` (title with today's date beneath) → optional
  segmented control → scrolling content. Home opens with a greeting instead.
- **Bottom navigation:** five tabs: Home · Programs · Explore · Progress ·
  Nutrition. The active item sits on a charcoal pill.
- **Figure-led layout** (Explore): the visual takes the left ~44%; the title,
  part rows and the expandable Latin name take the right. Reuse this split
  for any "pick on a picture" screen.
- **Tablet / foldable:** a navigation rail and two-column bento, with 24 px margins.

## 5. Elevation & depth

- **Module:** `card` fill, a 1 px highlight border, and a soft shadow
  (`0 1 2 rgba(20,20,25,.04), 0 8 24 rgba(20,20,25,.06)`). Dark modules use the border only.
- **Inner panel:** one tone darker (`surface`), with no shadow.
- **Raised control:** `raised` fill, 1 px `border`, and a hairline shadow.
- **Coral glow:** only on filled coral controls (`accent` at 35%, 16–18 px blur,
  y +4–6) and on the body-figure highlight. Never on cards.
- **Sheets:** `xl` radius, a drag handle, and a 28% ink scrim.

## 6. Shapes

| Element | Radius |
|---|---|
| Sheets, hero modules | `xl` 28 |
| Cards, panels, exercise cards | `lg` 20 |
| Inputs, part rows, photos, inner panels | `md` 14 |
| Chips, badges, thumbnails | `sm` 8 (thumbnails 10) |
| Buttons, segmented controls, filter chips, pills | `full` |

Nested elements use a smaller radius than their parent.

## 7. Components

Shared widgets live in `lib/core/widgets/`. The coral pieces are in
`accent.dart`.

### Buttons
- **Main action (coral, `AccentButton`):** a 52 px `full` pill filled with the
  `accentFill → accentFillEnd` gradient, `onAccent` label at weight 600, an
  optional leading icon, and a coral glow. Only one per screen. When
  unavailable (e.g. *Current split*), use an outline pill with muted text.
  `compact: true` gives a 40 px pill for a list row (the Programs *Start*).
- **Primary (neutral):** a charcoal pill (light) or light pill (dark), 48 px.
  Use it for actions that repeat within a screen (*Log set 2*, *Add chunk*)
  and for confirmations.
- **Secondary:** a `raised` pill with a 1 px `border` and ink text.
- **Outlined accent:** an `accentContainer` fill, a 60% `accent` border and
  `accentText` icon, for secondary but encouraged actions (*Watch form videos*).
- **Icon button:** a 44 px `raised` circle with a 20 px Lucide icon.
- **Destructive:** an outline pill in `error`, always confirmed (*Clear data*).

### Chips, toggles and segmented controls
- **Filter or selection chip (`AccentChip`):** unselected, a hairline outline
  with `textSecondary`; selected, the coral gradient, an `onAccent` label at
  600 and a coral glow. Use it for muscle chips, days-per-week and the
  Programs track switcher.
- **Compact toggle (`CompactToggle`):** a small two-way switch such as
  GYM | HOME or FRONT | BACK. Labels are micro-labels; the selected segment
  is a `raised` pill. It stays neutral because it switches a view, not a
  selection.
- **Segmented control (`SlidingSegmentedControl`):** for top-of-page view
  switches (Muscles | Splits, Stats | History, Daily log | Meal plan).
  Neutral.

### Cards & modules (`AppCard`, `ModuleHeader`)
- A title in `headline-md`, with an optional muted subtitle and a trailing action.
- **Today card (Home):** the next workout with day name, week, exercises and
  minutes, and the coral main action *Start*. Its gradient
  (`heroStart → heroEnd`) is the screen's only decorative surface.
- **KPI strip (Home):** Streak · Sessions · Volume · Sets, separated by
  hairlines, using `metric-card` values and a `DeltaPill`.
- **This week (Home):** day dots: trained days filled with the charcoal
  anchor plus a ✓; today drawn as an `accent` ring.
- **Program day card:** an order disc, the day name, `N exercises · ~M min`,
  and a trailing action:
  - next day: coral border plus the coral *Start*;
  - running: *Resume*;
  - done: a positive *Done ✓* badge;
  - rest day: a moon icon and *Rest day · nothing to log*.

### Live workout
- **Session panel:** elapsed time in `metric-hero`, a target, and a pause
  `RoundIconButton`. The progress bar is `accent` on `track`, with
  `N of M sets`.
- **Exercise tile:**
  - **Header:** an icon chip, the name and the prescription.
  - **Steppers:** 52 px fields with − and +, weight stepping by 2.5 kg.
  - **Logged sets:** rows below with a positive ✓.
  - **Distance sets:** distance and minutes:seconds, with a live pace line.
- **Countdown (timed sets):** a gauge ring in `accent` while running and
  muted while paused, with Start/Pause, Reset and *Log early*.
- **Rest timer:** a neutral bar under the plan. The block's `restSeconds`
  sets it; `0` hides it.
- **Info button:** on exercises linked to the library, it opens the
  exercise sheet.

### Explore
- **Body figure:**
  - **Drawing:** custom-painted front and back views. The silhouette is
    `body`, muscle zones `muscle` with `line` outlines and anatomy detail
    lines.
  - **Selected part:** an `accent` radial gradient with a blur glow and a
    white hairline. The rest of that muscle gets a 16% `accent` tint.
  - **Crosshair:** dashed guides with a white target ring, aimed at the
    figure's left side for paired muscles.
  - **Animation:** highlights fade in over 420 ms.
- **Muscle part row:** the name plus a FRONT/BACK micro-label. When selected,
  the row gets the `accentContainer` tint, a 70% `accent` border, and the
  tag in `accentText`.
- **Recommendation card:**
  - **Collapsed:** an 84 × 64 photo thumbnail, the name at 600, an equipment
    chip, `metric-table` sets × reps, and a focus meter (3 bars = primary,
    2 = assists).
  - **Top pick:** an outlined *TOP PICK* pill and a 40% `accent` border.
  - **Opened:** an `accentContainer` tint, the cue, a start/finish photo
    viewer, numbered steps with `accentText` numerals, *Works* tags, and the
    outlined-accent video button.
- **Split card / split detail:**
  - level as a micro-label in its semantic tone, days and schedule as
    micro-labels;
  - day muscles as an `accentText` micro-label line, with no-break spaces
    so a wrapped line never starts with "·";
  - the coral main action *Use this split*.

### Badges & pills
- **Status (`StatusBadge`, `TagPill`):** 22 px, container plus text from the
  semantic table.
- **Accent outline (`OutlinePill`):** for *TOP PICK* and *CURRENT*.
- **Dark callout (`CalloutPill`):** a chart highlight value such as `+12%`.

### Inputs
- A 46–52 px field with a `raised` fill, `md` radius and 1 px `border`, and
  the label above in `label-regular`.
- Focus: a 1.5 px `primary` border, no glow.
- The search field has a leading search icon and a clear button.

### Data visualisation
- **Bars (`ThinBarChart`):** thin bars in `barMuted`. The current or selected
  period is `accent`, with a dark callout pill above. No gridlines.
- **Sets per muscle:** direct sets in `accent`, assisting sets in `accent` at
  35%, and a neutral shaded band for the 10–20 target.
- **Gauge (`GaugeArc`):** a 270° arc with a `track` background. The fill is
  `accent` while something is running (a timed hold's countdown), and
  `primary` for ratios such as the weekly goal or rest-pause reps.
- **Sparklines, line charts:** 1.25–1.5 px `primary` strokes. Projections
  are dashed.
- Semantic colours appear in charts only for deltas.

### Empty states (`EmptyState`)
An icon chip, one line of ink, a muted hint and at most one action. No
illustrations.

### Home-screen widgets (Android)
The quote card and the quote + week widgets are drawn natively
(`QuoteCardRenderer.kt`) with the same tokens as the Home tab, in light and
dark. As on Home, today's week dot is an `accent` ring; trained days are
filled with the charcoal anchor.

## 8. Motion
- 200–250 ms standard easing for state changes: chips, rows, toggles, card
  expand (240 ms), rotating chevrons.
- 420 ms ease-out-cubic for the figure highlight.
- Numbers change in place, with no count-up animations.
- Selecting a muscle on the figure scrolls its chip into view.

## 9. Adoption across the app

Every screen follows the coral rules. `test/core/design_rules_test.dart`
walks Home → Programs → day preview → live workout → Explore → split
detail → Progress → Nutrition. It fails if any screen shows more than one
coral main action, or if coral is missing from the places below.

| Area | Coral today |
|---|---|
| Home | *Start workout* / *Resume workout* main action; today's week dot ring |
| Programs | Selected track chip (`AccentChip`); next or running day: `accent` border and a compact coral *Start* / *Resume* |
| Day preview / live workout | *Start ‹day› Workout*, then *Finish workout*; session progress bar; a running countdown ring |
| Explore | Selected muscle and part; *Use this split*; top picks, meters, set bars |
| Progress (and Home charts) | The current period's bar in every `ThinBarChart` |
| Nutrition | *Snap Meal* (camera) tile |
| Android widgets | Today's week dot ring |

When a new screen is added, add it to this table and to the design-rules test.

## 10. Checking a screen against this document

1. **Count filled coral controls.** At most one per screen.
2. **Check coral text.** It always uses `accentText`, never `accent`.
3. **Check text on coral fills.** It always uses `onAccent`, never hard-coded white.
4. **Check meaning.** No coral where it could be read as good or bad.
5. **Test and render it.**
   - `flutter test test/core/design_rules_test.dart` enforces rules 1 and the
     §9 placements.
   - `flutter test tool/screens/render_screens_test.dart` writes dark and
     light screenshots of every main screen to `build/screens/`, and fails on
     any overflow.
   - Extend both when a screen is added.
