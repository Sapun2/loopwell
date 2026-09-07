# Prompt for your cloud Claude Code console

Copy everything below the line into Claude Code once you have this whole `Loopwell_Flutter_App` folder open in your cloud workspace. It is written as a single self-contained brief — Claude Code there has no memory of this conversation, so the prompt repeats the context it needs.

---

I'm building the Assessment 3 mobile app for ICT725 (User Experience and Mobile Application Development). The app is called **Loopwell**, a daily habit tracker, and it's the Flutter front end of a Figma prototype I already built and reported on in Assessment 2.

This folder already contains a complete, hand-written Flutter app under `flutter_app/` — every screen, the theme, the data model, and local persistence are implemented (see `spec/PRD.md` for the full functional spec and `design/design_tokens.md` for the exact colours/type/spacing to preserve). What's in `flutter_app/lib/` is the real application code, not a stub — please treat it as a first draft to get running and polish, not something to rewrite from scratch.

Do the following, in order:

**1. Turn this into a runnable Flutter project.**
The `flutter_app/` folder has `pubspec.yaml` and `lib/` but no platform folders yet (no `android/`, `ios/`, etc. — those are machine-generated and weren't safe for me to hand-write). From inside `flutter_app/`, run:

```
flutter create --project-name loopwell --org com.example .
```

This generates `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` and merges in without touching my existing `lib/`, `pubspec.yaml`, or `analysis_options.yaml` (Flutter's `create` on a directory that already has a pubspec is additive by default). If it prompts about overwriting `lib/main.dart` or `pubspec.yaml`, say no / keep mine.

**2. Install dependencies and check for issues.**
```
flutter pub get
flutter analyze
```
Fix anything `analyze` flags. A few things to check first if you see errors, since I wrote this without a live SDK to compile against and Flutter's API has shifted some class names over time:
- `CardTheme` vs `CardThemeData` in `lib/theme/app_theme.dart` — if analyze wants the `Data`-suffixed name, rename it there.
- `WidgetState` / `WidgetStateProperty` (used in the Switch theme) — these are the current names; if your SDK is older and wants `MaterialState` instead, swap it.
- Anything using `.withOpacity(...)` — if analyze suggests `.withValues(alpha: ...)` instead, that's a safe mechanical rename.
These are the only spots I was genuinely unsure about; everything else should be solid. If analyze surfaces something outside these three, fix it and note what it was — I'd like to know for next time.

**3. Run it on an emulator and click through everything.**
```
flutter run
```
Walk the full flow: Onboarding (3 slides, Skip, Get Started) → Home (seeded with 3 sample habits) → tap a habit card to mark it done → tap into Habit Detail (check the streak/rate/heat map look right) → FAB to Add Habit (try the icon/colour/weekday/reminder picker) → Settings (toggle Appearance between Light/Dark/System, open Data & Export and confirm it shows real JSON, try Sign Out and confirm it goes back to Onboarding and Home still remembers your habits after). Fix anything that looks visually off compared to the screenshots in `design/screenshots/` and the tokens in `design/design_tokens.md` — colours, spacing, and corner radius should match closely, that is a scored rubric criterion (Layout and visual appeal).

Also resize/try a second device profile (a compact phone and a larger one) to confirm nothing overflows — "fully responsive" is explicitly graded.

**4. Capture screenshots for the assessment report.**
I need one clean screenshot each of: Home (with habits showing, some done some not), Add/Edit Habit, Habit Detail & Stats (with a populated heat map — the seed data already has history, or mark a few more days complete first), Settings, and one Onboarding slide. Save them somewhere I'll grab from this workspace afterwards — a `screenshots/` folder at the project root is fine.

**5. Git and GitHub.**
```
git init
git add .
git commit -m "Loopwell: initial Flutter implementation"
```
Then create a **public** (or at least accessible-to-marker) GitHub repository and push to it — via the `gh` CLI if it's available (`gh repo create loopwell --public --source=. --push`), otherwise create the repo on github.com and add it as a remote manually. The Assessment 3 rubric explicitly checks that the GitHub link is provided and valid, so double check the repo is actually reachable (not private) once it's up, and send me the URL.

**6. Tell me when you're done, and report back:**
- The GitHub repo URL
- Whether `flutter analyze` is clean
- Any screen that doesn't match the Figma design closely and why
- Confirmation all six screens are reachable and every back button returns to the right place

## Optional, only if you have time left

- Wire up real OS notifications for the reminder time using `flutter_local_notifications` (Android + iOS permission setup included). I deliberately left this out of the front-end-only scope — the reminder time is fully captured and stored, it just doesn't fire an alert yet — but if it's easy to add cleanly, it's a nice extra. If you do this, tell me, because it changes what I write in the assessment report's "remaining functionality" section.
- A couple of `flutter_test` widget tests (e.g. adding a habit updates the Home list, toggling completion updates the streak) — not required by the rubric but cheap evidence of "no errors" for the Functionality criterion.

## What NOT to do

- Don't invent or change the functional requirements — they're fixed in `spec/PRD.md` because they need to match what's already written in the Assessment 2 report.
- Don't add a backend, login, or cloud sync — the whole design (see the Privacy non-functional requirement) is that this runs fully offline on-device. Adding auth would contradict the Assessment 2 report.
- Don't restyle away from the indigo/teal palette in `design/design_tokens.md` — that has to stay consistent with the Figma prototype for the "consistent with prototype design" rubric line.
