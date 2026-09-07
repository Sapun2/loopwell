# Presentation & demo script — Loopwell

**ICT725 Assessment 3, weeks 11–12. Worth 10 of the 40 marks.**
Target: a succinct summary of the report, demonstrated live through an emulator.

Aim for **5 minutes**: about 1 minute talking, 3 minutes demonstrating,
1 minute closing. The rubric rewards a *succinct* summary with confidence and
eye contact — so the goal is to look like you are using an app you know well,
not reading notes.

---

## Before you present (do this the day before, not on the day)

1. Start the Android emulator and run `./run.sh android`. Leave it running.
2. Click through the whole flow once so everything is warm.
3. **Reset to a clean state**: uninstall the app from the emulator, then run
   again. This re-seeds the five sample habits with three done — which is
   exactly the state that makes the Home screen look best.
4. Set the emulator to **Light** theme so it matches your Figma prototype, and
   have the Figma file open in a second browser tab.

---

## The demo path (in this order)

| # | Do this | Say this |
|---|---|---|
| 1 | App opens on **Onboarding** | "Loopwell is a daily habit tracker. Three slides introduce the idea, then it never shows them again." |
| 2 | Tap **Get Started** → **Home** | "This is the whole app in one screen — a progress card that counts only what's actually scheduled today, and every habit below it." |
| 3 | Tap the **circle** on *Morning Run* | "Logging a habit is one tap. No dialog, no gesture to learn. Watch the streak, the summary and the ring all update together." |
| 4 | Tap it again to undo | "And it's reversible, because people mis-tap." |
| 5 | Tap the **card body** of *Read 20 Pages* | "Tapping the card instead opens the detail: current streak, best streak, completion rate, and a five-week heat map. The heat map is the point — it turns a percentage into a pattern." |
| 6 | Back → tap **+** | "Creating a habit: name, icon, colour, frequency, reminder." |
| 7 | Type a name, tap **Create Habit** | "Everything is pre-filled with a sensible default, so the fastest path is type a name and save." |
| 8 | Show it on **Home** | "And it's straight on the dashboard." |
| 9 | **Settings** tab → **Appearance → Dark** | "Settings has a full dark theme — that's beyond what the Figma prototype covered." |
| 10 | Back to Light → **Data & Export** | "No account and no backend. Everything is on the device, and the user can see and copy all of it as JSON." |

**If asked "what isn't finished?"** — answer directly, it is a strength:
> "Reminders. You can set one, it saves and displays, but it doesn't fire an OS
> notification yet. That needs notification permissions and native scheduling,
> and I wasn't willing to demo scheduling code I couldn't verify on a real
> device. It's the next piece of work and the UI for it is already done."

---

## Your opening (about 30 seconds)

> "My app is Loopwell — a daily habit tracker. Most habit apps fail in one of
> two ways: they take so much setup that logging becomes a chore, or they reset
> your streak to zero the moment you miss a day, which is exactly when people
> quit. Loopwell logs a habit in one tap and keeps an honest streak. Seven of my
> eight requirements are fully working; I'll show you the main ones."

## Your closing (about 30 seconds)

> "So: one-tap logging, honest progress, a visual history, and full create /
> edit / delete — all cross-platform Flutter, all working offline with no
> account. The Figma prototype and the GitHub repo are both in my report. The
> one outstanding piece is OS-level notifications, which I've scoped rather than
> faked."

---

## Have these ready to show if asked

- **Figma prototype:** <https://www.figma.com/design/yZf92ARQOn7lqavVbicKaS/Loopwell---UX-Prototype--ICT725-?node-id=14-3>
- **GitHub repo:** <https://github.com/Sapun2/loopwell>
- **Prototype vs. build:** put `design/screenshots/hifi_2_home.png` beside the
  running app. They match closely — that is the "consistent with prototype
  design" criterion, and showing it is faster than claiming it.

---

## Safety net

If the emulator misbehaves on the day, `./run.sh chrome` opens the same app in
the browser in about 20 seconds. Open Chrome DevTools (`F12`) and switch on the
device toolbar so it still presents as a phone. Say plainly that you're showing
the web build of the same codebase — an app that runs everywhere is a point in
your favour, not an excuse.
