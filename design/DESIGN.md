---
name: Paper & Ink · Coral
colors:
  surface: '#F2F1EE'
  surface-dim: '#E5E4E0'
  surface-bright: '#FFFFFF'
  surface-container-lowest: '#FFFFFF'
  surface-container-low: '#FFFFFF'
  surface-container: '#F2F1EE'
  surface-container-high: '#ECEBE7'
  surface-container-highest: '#E8E7E3'
  on-surface: '#151515'
  on-surface-variant: '#5C5C58'
  inverse-surface: '#151515'
  inverse-on-surface: '#F2F2F3'
  outline: '#6A6A66'
  outline-variant: '#E5E4E0'
  surface-tint: '#151515'
  primary: '#151515'
  on-primary: '#FFFFFF'
  primary-container: '#2E2E2C'
  on-primary-container: '#F2F2F3'
  inverse-primary: '#C8C8CC'
  secondary: '#5C5C58'
  on-secondary: '#FFFFFF'
  secondary-container: '#E4E4E7'
  on-secondary-container: '#151515'
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
  background: '#F4F4F1'
  on-background: '#151515'
  surface-variant: '#E8E7E3'
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
  accent-fill-end: '#BF3F1C'
  on-accent: '#FFFFFF'
  accent-container: '#FCEBE4'
typography:
  display:
    fontFamily: Geist
    fontSize: 34px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.035em
  headline-xl:
    fontFamily: Geist
    fontSize: 30px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Geist
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: -0.025em
  title-lg:
    fontFamily: Geist
    fontSize: 19px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: -0.0125em
  title-sm:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: -0.007em
  body-lg:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0em
  body-md:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-sm:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0em
  metric-hero:
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
  label-uppercase:
    fontFamily: Geist
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 12px
    letterSpacing: 0.09em
  label-regular:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
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

**One-line summary:** warm paper or near-black surfaces, a clean grotesk for
words, figures set like a well-kept training log, and one coral accent that
always means *this is what you're doing now*.

## 1. Brand & style

- **Tone:** steady, precise, encouraging without hype. A training log you
  trust, not a game. Numbers are stated plainly: `4 × 8–12`, `62.5 kg`,
  `5:30 /km`.
- **Aesthetic:** warm paper (light) or near-black (dark) canvas, white or
  graphite modules on a hairline, large tight-tracked titles, monospaced
  figures only, generous whitespace. Restraint reads as premium: flat fills,
  no glows, one level of boxes inside a module.
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
| Canvas (`background`) | `#F4F4F1` | `#09090A` | Page behind everything, and the bottom bar |
| Inner panel (`surface`) | `#F2F1EE` | `#1C1C1F` | Stepper wells, segmented tracks, badges, empty-state panels |
| Module (`card`) | `#FFFFFF` | `#141416` | Cards and panels |
| Raised control (`raised`) | `#FFFFFF` | `#202023` | Icon buttons, segmented thumbs, search field |
| Hairline (`border` / `divider`) | `#E5E4E0` / `#ECEBE7` | `#26262A` / `#222226` | Borders, dividers, exercise separators |
| Ink (`textPrimary`) | `#151515` | `#F2F2EF` | Titles, values |
| Muted ink (`textSecondary`) | `#5C5C58` | `#A6A6A2` | Labels, captions, axis text (≥4.5:1 on every surface) |
| Faint ink (`textMuted`) | `#6A6A66` | `#8E8E8A` | Micro-labels, dates above titles, metadata |
| Ink anchor (`primary`) | `#151515` | `#F2F2EF` (inverts) | Structure: selected chips, neutral buttons, non-current chart bars |
| Tracks (`track` / `barMuted`) | `#E8E7E3` / `#D5D4CF` | `#26262A` / `#36363B` | Progress tracks, the nav indicator, inactive bars |

### Coral accent: focus and the main action

Coral is the app's single accent. It always means **this is what you're
doing now**: the selected item, the next or current workout, live progress,
or the one main action on a screen.

| Token | Light | Dark | Use |
|---|---|---|---|
| `accent` | `#E4572E` | `#FF7A59` | **Graphics only:** a selected highlight, the current bar, meters, borders, the body-figure highlight and its glow |
| `accentText` | `#B83A18` | `#FF7A59` | **Coral text and small icons** on any surface |
| `accentFill` → `accentFillEnd` | `#CC4722` → `#BF3F1C` | `#FF7A59` → `#F86A4A` | Fill for coral controls: a near-flat sheen, top-left to bottom-right |
| `onAccent` | `#FFFFFF` | `#161618` | Text and icons on the filled gradient |
| `accentContainer` | `#FCEBE4` | `#2A1711` | Soft tint behind a selected row or an opened card |

**Measured contrast.** Never pair coral differently from this table without
re-measuring.

| Pairing | Light | Dark | Requirement |
|---|---|---|---|
| `accentText` on canvas / module / raised | 5.21 / 5.74 / 5.74 | 7.75 / 7.17 / 6.33 | Text needs 4.5:1 |
| `onAccent` on `accentFill` / `accentFillEnd` | 4.68 / 5.33 | 7.17 / 6.27 | Text needs 4.5:1 |
| `accentText` on `accentContainer` | 4.96 | 6.66 | 4.5:1 |
| `accent` graphic vs its module | 3.68 | 7.17 | Graphics need 3:1 |
| `textMuted` on canvas / module / inner panel | 4.93 / 5.43 / 4.81 | 6.05 / 5.60 / 5.17 | Text needs 4.5:1 |

Two traps:
- Light `accent` (`#E4572E`) is too pale for small text, at 3.68:1. Use `accentText`.
- In dark mode, white on coral fails at 2.57:1. That's why `onAccent` is dark ink there.

**Where coral goes:**
- **The one main action** on a screen, as a filled coral pill with no shadow:
  *Start workout*, *Use this split*, the widget's *Start* button.
  Only one per screen. Actions repeated down a list, such as *Log set*, use
  the neutral primary button.
- **Selection on a picture or in a list:**
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
- **Navigation chrome and filter chips.** The bottom bar's active item and a
  selected filter chip are ink: choosing a view is structure, not focus.
- **Two main actions.** At most one filled coral button per screen.
  Everything else stays small: text, borders, rings, meters.
- **Glows.** Coral never casts a shadow. The body-figure highlight is the
  only coral blur.

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

Two families, both OFL and bundled so the app works offline:

- **Geist** (400/500/600) for every word: titles, body, labels, buttons, nav.
- **JetBrains Mono** (400/500/600) for figures only, through the `AppText.metric*`
  styles: weights, reps, set tables, timers, paces, KPI values. Fixed-width
  digits line up in set tables, and the contrast with Geist marks a number
  as data.

| Style | Size / line | Weight | Use |
|---|---|---|---|
| `displayMedium` | 34 / 40, −1.2 | 600 | The Home hero's day name |
| `headlineMedium` | 30 / 36, −0.9 | 600 | Tab titles (`DayAppBar`), the Home greeting |
| `headlineSmall` | 24 / 30, −0.6 | 600 | Screen sub-titles (day name in a workout) |
| `titleMedium` | 16 / 22 | 600 | Card titles (`ModuleHeader`), block names |
| `titleSmall` | 14 / 20 | 600 | Exercise names, button labels |
| `bodyMedium` | 14 / 20 | 400 | Body copy, cues, steps |
| `bodySmall` | 12 / 16 | 400 | Captions, metadata |
| `labelMedium` | 12 / 16 | 500 | Field labels, the date line above a title |
| `metricHero` (mono) | 32 / 38 | 500, −0.045em | Elapsed time, big stats |
| `metricCard` (mono) | 18 / 24 | 500 | KPI values, stepper values |
| `metricTable` (mono) | 13 / 18 | 500, tabular | Set rows, `4 × 8–12`, pace |
| **Micro-label** (`MicroLabel`) | 10–12 | 600, +0.1em, uppercase | Eyebrows and tags: `TODAY'S SESSION`, `02 / 14 · DELTOID`, `TOP PICK` |

- Large titles are tight-tracked (negative letter-spacing grows with size).
  Hierarchy comes from size and weight. Avoid 700 and heavier.
- Tab pages put the date first, small and muted, then the title large.
- Sentence case by default. Uppercase only for micro-labels and block badges.
- Words never use a mono style, even beside a number (`Lateral deltoid`,
  `Protein`, a badge like `1 workout`). Badges are Geist with tabular figures.
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
- **Tab pages:** `DayAppBar` (today's date, then the title large) → optional
  segmented control → scrolling content. Home opens with the same date line
  and a greeting.
- **Home KPIs** sit in a 2 × 2 grid, so every figure stays whole on a phone;
  nothing scrolls sideways out of view.
- **Bottom navigation:** five tabs: Home · Programs · Explore · Progress ·
  Nutrition, on the canvas colour. The active item is ink on a soft `track`
  pill; the rest are `textMuted`.
- **Figure-led layout** (Explore): the visual takes the left ~44%; the title,
  part rows and the expandable Latin name take the right. Reuse this split
  for any "pick on a picture" screen.
- **Tablet / foldable:** a navigation rail and two-column bento, with 24 px margins.

## 5. Elevation & depth

- **Module:** `card` fill and a 1 px `border` hairline. In light mode, one
  wide, faint shadow (`0 1 1 rgba(21,21,21,.03), 0 12 32 rgba(21,21,21,.04)`);
  dark modules use the hairline only.
- **One level of boxes inside a module.** Rows and exercises inside a module
  are separated by hairlines, not boxed. Inputs (stepper wells) are the
  `surface` tone with no border.
- **Raised control:** `raised` fill, 1 px `border`, and a hairline shadow in light.
- **No glows.** Coral controls and selected chips are flat. The body-figure
  highlight is the only blurred colour.
- **Sheets:** `xl` radius, a drag handle, and a 32% ink scrim.

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
- **Main action (coral, `AccentButton`):** a 54 px `full` pill filled with the
  near-flat `accentFill → accentFillEnd` fill, an `onAccent` label at 15/600,
  an optional leading icon, and no shadow. Only one per screen. When
  unavailable (e.g. *Current split*), use an outline pill with muted text.
  `compact: true` gives a 40 px pill for a list row (the Programs *Start*).
- **Primary (neutral):** an ink pill (light) or light pill (dark), 48 px.
  Use it for actions that repeat within a screen (*Log set 2*, *Add chunk*)
  and for confirmations.
- **Secondary:** a `raised` pill with a 1 px `border` and ink text.
- **Outlined accent:** an `accentContainer` fill, a 60% `accent` border and
  `accentText` icon, for secondary but encouraged actions (*Watch form videos*).
- **Icon button:** a 44 px `raised` circle with a 20 px Lucide icon.
- **Destructive:** an outline pill in `error`, always confirmed (*Clear data*).

### Chips, toggles and segmented controls
- **Filter or selection chip (`AccentChip`):** unselected, a `raised` pill
  with a hairline outline and `textSecondary`; selected, a solid ink
  (`primary`) pill with an `onPrimary` label at 600. No glow. Use it for
  muscle chips, days-per-week and the Programs track switcher.
- **Compact toggle (`CompactToggle`):** a small two-way switch such as
  GYM | HOME. A `surface` track; the selected segment is a `raised` pill with
  a hairline shadow. Labels are micro-labels. It stays neutral because it
  switches a view, not a selection.
- **Segmented control (`SlidingSegmentedControl`):** for top-of-page view
  switches (Muscles | Splits, Stats | History, Daily log | Meal plan).
  Neutral.

### Cards & modules (`AppCard`, `ModuleHeader`)
- A title in `headline-md`, with an optional muted subtitle and a trailing action.
- **Today card (Home):** a micro-label eyebrow (`TODAY'S SESSION`), the day
  name in `displayMedium`, week · exercises · minutes, and the coral main
  action *Start workout* beside a 54 px preview button.
- **KPI grid (Home):** Streak · Sessions / Volume · Sets in a 2 × 2 grid with
  hairline dividers, `metric-card` values and a `DeltaPill`.
- **This week (Home):** day dots: trained days filled with the ink
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
  - **Separation:** a top hairline inside the block card, never a box of its own.
  - **Header:** an icon chip, the name in `titleSmall` and the prescription.
  - **Steppers:** 52 px `surface` wells with − and +, weight stepping by 2.5 kg.
- **Block card:** an order disc, the block name, a pill badge for the block
  type (a coloured dot on `surface`), and the block's note as an unboxed line
  with an info icon.
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
  - **Drawing:** anatomical SVG paths (react-native-body-highlighter, MIT,
    generated into `anatomy_paths.g.dart` by `tool/build_anatomy.py`),
    painted with a `CustomPainter`. The silhouette is `body`, muscles are
    `muscle` with `line` seams; head, hands, knees and feet are a quieter
    blend and never tappable. Parts of a muscle (e.g. rectus femoris, upper
    chest) are cut from the library shapes with rect or oval masks.
  - **Selected part:** an `accent` radial gradient with a blur glow and a
    white hairline. The rest of that muscle gets an 18% `accent` tint.
  - **Crosshair:** dashed guides, a white target ring that eases in, three
    slowly rotating arcs and a centre dot, aimed at the figure's left side
    for paired muscles.
  - **Animation:** on each new selection a single scan band sweeps down the
    silhouette and the highlight fades in, all within 900 ms. Nothing loops.
  - **Credit:** shown in "How these picks were chosen" and on the licences
    page.
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
- **Status (`StatusBadge`, `TagPill`):** 24 px, container plus text from the
  semantic table, in Geist 12/600 with tabular figures.
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
(`QuoteCardRenderer.kt`), in light and
dark. As on Home, today's week dot is an `accent` ring; trained days are
filled with the ink anchor. *Not yet restyled:* the widget still draws the earlier Pearl Ledger greys and JetBrains Mono text; bring `QuoteCardRenderer.kt` onto the Paper & Ink tokens and Geist next.

## 8. Motion
- 200–250 ms standard easing for state changes: chips, rows, toggles, card
  expand (240 ms), rotating chevrons.
- 900 ms for the figure when a view first shows: one scan sweep, then the
  highlight fades in.
- 480 ms ease-in-out glide between selections on the same view (another part
  or another muscle): the old highlight fades out, the new fades in, and the
  target slides across with one soft pulse. No scan replay.
- 640 ms turn when the figure changes side: the old side rotates about the
  spine to edge-on, the new side rotates in, with perspective and a slight
  dip in size at the midpoint. The side always follows the selected muscle
  or part; there is no manual FRONT/BACK switch.
- 280 ms fade with a 1.5% rise (`SmoothSwap`) when the muscle title and parts
  or the recommendation list change; the height eases at the same time.
- Exercise photos: one large photo at the top of an opened card or sheet
  (the card's thumbnail tucks away). It alternates between the start and
  finish photo every 1.8 s with a 450 ms cross-fade, with no labels over the
  photo; a tap flips at once. It stays still when the system asks for
  reduced motion.
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
| Programs | Next or running day: `accent` border and a compact coral *Start* / *Resume* (the selected track chip is ink) |
| Day preview / live workout | *Start ‹day› Workout*, then *Finish workout*; session progress bar; a running countdown ring |
| Explore | Selected part on the figure and its row; *Use this split*; top picks, meters, set bars (the selected muscle chip is ink) |
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
     light screenshots of every main screen to `build/screens/`, with shadows
     blurred as on a device, and fails on any overflow.
   - Extend both when a screen is added.
