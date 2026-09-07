# Loopwell — Assessment 3 Build Specification

ICT725 User Experience and Mobile Application Development. This document is the bridge between the Assessment 2 prototype (Figma + report) and the Assessment 3 Flutter front end. It reuses the functional and non-functional requirements from Assessment 2 as the rubric instructs, then turns them into a concrete Flutter build plan.

## 1. App title and one-line pitch

**Loopwell** — *Small steps, every day.* A daily habit tracker for iOS and Android that logs a habit in under two taps and never punishes a missed day.

## 2. Functional requirements (reused from Assessment 2, Section 4)

| ID | Requirement | Assessment 3 status |
|---|---|---|
| FR1 | Onboarding: introduce the value proposition and route into setup. | Fully implemented |
| FR2 | Daily dashboard: every habit with status, one tap completion, and a summary. | Fully implemented |
| FR3 | Create habit: name, icon, colour, and frequency. | Fully implemented |
| FR4 | Reminders: a per habit reminder with a set time. | Partly implemented — see note below |
| FR5 | Mark complete or undo: toggle completion for the day. | Fully implemented |
| FR6 | Habit detail: streak, completion rate, and a heat map. | Fully implemented |
| FR7 | Edit or delete an existing habit. | Fully implemented |
| FR8 | Settings: notifications, appearance, data export, profile. | Fully implemented |

**FR4 note, for the report's "remaining functionalities not implemented" section:** the app lets a user turn a reminder on, pick a time, and see it stored and displayed on the habit (the front-end UI is complete). Actually firing an OS-level push notification at that time requires platform notification permissions and native scheduling (`flutter_local_notifications` plus Android/iOS manifest changes) that sit outside plain front-end UI work and are easy to get wrong without a real device to test on. It is left as a clearly scoped next step rather than bolted on and left untested. This is a legitimate, honest answer to the report's required "remaining functionalities" section — do not present it as a shortcoming without this explanation.

That is 7 of 8 requirements fully working end to end, which comfortably clears the rubric's "minimum two major features" floor and supports the High Distinction Functionality descriptor ("complete functionality developed for complex processes with no errors").

## 3. Non-functional requirements (reused from Assessment 2, Section 5)

| Requirement | How the Flutter build satisfies it |
|---|---|
| Usability — mark complete usable without instruction | One tap on the status circle on the Home card; no confirmation dialog, no swipe gesture to learn |
| Performance — transitions resolve within ~300ms | Use Flutter's default page transitions (`MaterialPageRoute`), avoid synchronous disk I/O on the UI thread (SharedPreferences writes are `await`ed but fired off after the UI already updated optimistically) |
| Accessibility — WCAG 2.1 AA contrast, 44pt touch targets | All colour pairs below meet 4.5:1 text contrast on their background; every tappable widget has a minimum 44x44 hit area (wrap small icons in `SizedBox`/`InkWell` padding, not bare `IconButton` at default 24px) |
| Consistency — one shared design system throughout | See `design/design_tokens.md`; `lib/theme/app_theme.dart` is the single place colours/type/spacing are defined, nothing is hardcoded per screen |
| Privacy — no account needed, data stored on device | No backend, no auth. All habits persist locally via `shared_preferences` (JSON-encoded). This also means there is nothing to configure for the marker to run the app — it works offline out of the box |

## 4. Data model

```
Habit
  id            String   (generated on create, stable for the habit's lifetime)
  name          String
  iconKey       String   (key into a fixed icon map, see habit_icons.dart)
  colorIndex    int      (0-5, indexes AppColors.habitSwatches — the 6 swatches in design_tokens.md)
  weekdays      List<int> (1=Mon .. 7=Sun; defaults to all 7, i.e. daily)
  reminderHour  int?     (nullable — null means no reminder set)
  reminderMinute int?
  completions   List<String> (ISO "yyyy-MM-dd" dates the habit was marked done)
  createdAt     String   (ISO date)
```

Derived, not stored: `currentStreak` (consecutive days up to today with a completion), `completionRate(days)` (fraction of the last N scheduled days completed). Both are pure functions over `completions`, computed on read — do not persist them, they would go stale.

## 5. Navigation map (must match the Figma prototype exactly)

```
Onboarding (3 slides, PageView)
  slide 1 → Skip → Home
  slide 2 → Skip → Home
  slide 3 "Get Started" → Home
  (only shown once — a persisted "onboarding_complete" flag skips straight to Home after)

Home (Today)
  habit card tap (body)        → Habit Detail
  habit card tap (status dot)  → toggles completion in place, stays on Home
  FAB (+)                      → Add Habit
  settings icon (AppBar)       → Settings

Add / Edit Habit
  Save   → pops back to Home (or Detail, if opened from there for editing)
  Delete (edit mode only) → confirm dialog → pops back to Home
  back arrow → discard, pop back

Habit Detail & Stats
  Edit (AppBar action) → Add/Edit Habit, pre-filled
  back arrow → Home

Settings
  Appearance → inline Light/System/Dark selector, applies immediately
  Notifications toggle → persisted, does not yet schedule OS notifications (see FR4 note)
  Data & Export → shows a dialog with the full JSON export, and a "Copy to clipboard" button
  Sign Out → confirmation dialog → clears the onboarding flag and returns to Onboarding (there is no real account, so this doubles as a "reset" — be upfront about that in the report rather than pretending it is a real sign-out)
```

Every screen must be reachable and every back-action must return to where the user came from — the Assessment 3 rubric explicitly checks that "pages of the app are linked with each other correctly."

## 6. Screen-by-screen UI spec

Cross-reference the matching screenshot in `design/screenshots/` for exact layout while building each screen; do not redesign from scratch.

**Onboarding** (`hifi_1a/1b/1c_onboarding.png`) — full-bleed illustration/icon area top half, headline + one line of supporting copy, page indicator dots, Skip (top right, slides 1-2 only) and a primary button bottom (Next / Get Started).

**Home** (`hifi_2_home.png`) — AppBar with app name and settings icon. Summary card near top ("3 of 5 done today" honest framing — count only habits scheduled for today). Scrollable list of habit cards below, each with icon in a tinted circle (tint = that habit's colour tint), name, current streak ("🔥 4"), and a tappable status circle on the trailing edge. FAB bottom right.

**Add / Edit Habit** (`hifi_3_addedit.png`) — single scroll form: name text field, icon grid picker, colour swatch picker, weekday chip row (Mon..Sun toggle), reminder switch + time picker row (enabled state shows the picked time), Save button pinned at the bottom. Sensible defaults pre-selected for a new habit (first icon, primary colour, every day, reminder off) so the form is usable with zero decisions if the user just wants to go fast.

**Habit Detail & Stats** (`hifi_4_detail.png`) — icon + name header, three stat chips (current streak, completion rate, total completions), a 5-week heat map grid (7 columns for weekdays, 5 rows for weeks, each cell shaded by the habit's colour at full opacity if completed that day / border-only if not, greyed if before the habit's `createdAt`), Edit action in the AppBar.

**Settings** (`hifi_5_settings.png`) — grouped list matching the screenshot sections exactly: profile row at top (name placeholder, "Member since <createdAt of first habit or app install>"), Preferences group (Notifications toggle, Appearance), Support group (Data & Export, About Loopwell, Send Feedback — the last two can be simple `AboutDialog`/`showDialog` stubs with real content, not TODOs), Sign Out at the bottom in the destructive colour.

## 7. How this maps to the Assessment 3 rubric

| Rubric criterion | What in this build earns it |
|---|---|
| Functionality (12) | 7/8 FRs fully working, all screens linked correctly and back-navigation correct, no backend so nothing to break at runtime, valid Figma link and (once pushed) valid GitHub link |
| Layout and visual appeal (7) | Single `app_theme.dart` sourced from `design_tokens.md`, screens built against the actual screenshots rather than approximated from memory |
| Usefulness and originality (5) | Same honest-framing pitch as the Assessment 2 report (Section 3) — carry that language into the Assessment 3 report's introduction rather than rewriting it |
| Usability (6) | One-tap completion, sensible defaults on the add-habit form, no dead-end screens |
| Presentation (10) | Not covered by this package — prepare separately closer to the week 11/12 tutorial; a real running emulator demo is worth more here than slides |

## 8. What the Assessment 3 report still needs (not covered by this folder)

The rubric asks for a written report (≥1500 words) with: title, introduction, FR/NFR (reuse the tables above), Figma link, screenshots of the implemented app with explanation, the FR4 remaining-functionality note above, a GitHub link, and a conclusion. That report should be written **after** the app is running and screenshotted from a real emulator — ask for it as a separate follow-up once you have those screenshots, rather than now while the screens don't exist yet as pixels.
