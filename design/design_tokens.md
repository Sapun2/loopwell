# Loopwell Design Tokens

Single source of truth for colour, type, and spacing values. These are the exact values used in the Figma prototype and in the Assessment 2 report's design system table (Section 7.6). The Flutter theme in `flutter_app/lib/theme/app_theme.dart` is generated directly from this file. If the two ever disagree, this file is correct and the Dart code should be fixed to match it.

## Colour palette

| Token | Hex | Used for |
|---|---|---|
| Primary (Indigo) | `#5B4FE8` | Buttons, links, active states, FAB |
| Primary Dark | `#4438C7` | Pressed / hover state of primary |
| Primary Tint | `#EFEDFD` | Selected chip backgrounds, subtle highlights |
| Teal (Accent) | `#00C2A8` | Streak indicators, positive/success status |
| Teal Tint | `#D9F5F0` | Success background fills |
| Coral | `#FF7A59` | Optional habit colour, destructive accents |
| Background | `#F6F7FB` | Screen background |
| Card | `#FFFFFF` | Cards, sheets, dialogs |
| Text | `#1F2430` | Primary text |
| Muted | `#8A8FA3` | Secondary / caption text |
| Border | `#E7E9F3` | Dividers, card borders, input outlines |

### Habit colour swatches (Add / Edit Habit colour picker)

These six were used across the Figma mockups for habit-specific colour tags:

1. `#5B4FE8` (Indigo, default)
2. `#00C2A8` (Teal)
3. `#FF7A59` (Coral)
4. `#F2A93B` (Amber)
5. `#6C6FE0` (Light Indigo)
6. `#3BB273` (Green)

Each has a matching tint (used as a light background behind the swatch or icon):

| Colour | Tint |
|---|---|
| `#00C2A8` | `#D9F5F0` |
| `#5B4FE8` | `#EFEDFD` |
| `#F2A93B` | `#FCEFD9` |
| `#FF7A59` | `#FFE7E0` |
| `#6C6FE0` | `#E8E8FB` |
| `#3BB273` | `#DFF5E7` |

## Dark mode

The Figma prototype only designed a light theme. The Flutter app adds a dark variant for the Settings > Appearance toggle (a genuine extra feature, not just a requirement). Dark mode should keep the same Primary and Teal accent hues, but invert background/surface/text:

| Token | Hex |
|---|---|
| Background (dark) | `#14151F` |
| Card (dark) | `#1E2030` |
| Text (dark) | `#F2F3F7` |
| Muted (dark) | `#9AA0B4` |
| Border (dark) | `#2C2E42` |

## Typography

Figma used **Liberation Sans / Arial** (a Helvetica-family sans). In Flutter, use the system default sans (`Roboto` on Android, `SF Pro` on iOS) via `ThemeData` — do not bundle a custom font, it is not required to match and adds risk.

Type scale (12 to 28 px in the Figma file):

| Style | Size | Weight | Use |
|---|---|---|---|
| Display | 28px | 700 (bold) | Onboarding headline |
| Title | 20px | 700 (bold) | Screen titles, AppBar |
| Subtitle | 16px | 600 (semibold) | Card titles, section headers |
| Body | 14px | 400 (regular) | Body text |
| Caption | 12px | 400 (regular) | Muted captions, timestamps |

## Spacing and layout

- Base grid: **8pt**. All padding/margin values should be multiples of 8 (8, 16, 24, 32).
- Screen margin: **24pt** on left/right.
- Card corner radius: **16px** (range used in Figma was 12 to 24px; 16 is the common case, 24 for the FAB/pill buttons, 12 for chips).
- Touch targets: **44x44pt minimum** on every tappable control (WCAG 2.1 AA), matches Assessment 2 Section 5.
- Reference frame size: **375 x 812** (iPhone-style), but the app must remain usable on wider Android phones — do not hardcode pixel widths, use `MediaQuery` / flexible layout.

## Screens to match (see `design/screenshots/`)

| File | Screen |
|---|---|
| `hifi_1a_onboarding.png` / `1b` / `1c` | Onboarding carousel, slides 1-3 |
| `hifi_2_home.png` | Home (Today) dashboard |
| `hifi_3_addedit.png` | Add / Edit Habit form |
| `hifi_4_detail.png` | Habit Detail & Stats (streak + heat map) |
| `hifi_5_settings.png` | Settings |
| `wireframes_overview.png` | Low-fidelity page map / navigation overview |

## Figma source

See `figma_link.txt` for the live interactive prototype link (Cover, Wireframes, and Hi-Fi Prototype pages, all frames wired with click-through interactions). Open it and click through the actual prototype before building — the screenshots are a static reference, the Figma file is the definitive one, especially for exact spacing and component states not visible in a single screenshot (pressed states, empty states).
