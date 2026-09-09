# How to run Loopwell

**Loopwell — a daily habit tracker.** ICT725 Assessment 3, Pradeep Bhandari.

No backend, no login, no API keys, no config. It runs offline and creates its
own sample data on first launch.

---

## Quick start — 3 steps

```bash
git clone https://github.com/Sapun2/loopwell.git
cd loopwell
./run.sh
```

On Windows, use `run.bat` instead of `./run.sh`.

That's it. `run.sh` installs the dependencies, finds a device, and launches. If
an emulator is running it uses it; if not, it opens in Chrome.

**The only prerequisite is Flutter.** If `flutter --version` doesn't work, get
it from <https://docs.flutter.dev/get-started/install> first — that's a
one-time, 10-minute install.

```bash
./run.sh            # auto: emulator if there is one, otherwise Chrome
./run.sh android    # force an Android emulator (starts it for you)
./run.sh chrome     # force the browser
```

---

## For the presentation — Android emulator in 5 steps

The demo is marked on an emulator, so set this up **before the day**.

> **Starting from a Mac with nothing installed?** `./setup_mac.sh` does all of
> this for you — Flutter, the Android SDK and an emulator, in one command. See
> [`HANDOVER.md`](HANDOVER.md), which also covers running it over AnyDesk.

1. Install **Android Studio** — <https://developer.android.com/studio>
2. Open it → **More Actions → Virtual Device Manager → Create Device**.
   Pick **Pixel 7**, download the suggested system image, click Finish.
3. Accept the SDK licences once (type `y` at each prompt):
   ```bash
   flutter doctor --android-licenses
   ```
4. Press ▶ next to your device to boot the emulator. Wait for the home screen.
5. ```bash
   ./run.sh android
   ```

After the first run, steps 1–3 never need repeating — it's just step 4 and 5.

> **Practice run:** do this once, end to end, a day before you present.
> The first Android build downloads Gradle and takes several minutes; every
> run after that takes seconds.

See [`DEMO_SCRIPT.md`](DEMO_SCRIPT.md) for what to click through and say.

---

## Other ways to run it

Run these from inside the `flutter_app/` folder.

```bash
flutter run -d chrome     # browser
flutter run               # a running emulator, simulator, or plugged-in phone
flutter run -d macos      # desktop (macOS needs full Xcode)
```

**iOS simulator** (macOS, needs full Xcode from the App Store):

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
open -a Simulator && flutter run
```

**A real Android phone:** turn on *Developer options → USB debugging*, plug it
in, accept the prompt, then `flutter run`.

**A shareable install file:**

```bash
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
```

---

## Checking the project is healthy

From inside `flutter_app/`:

```bash
flutter analyze   # expected: "No issues found!"
flutter test      # expected: "All tests passed!" (15 tests)
```

---

## What you should see

1. **Onboarding** — three indigo slides; *Skip*, or *Next* to *Get Started*.
2. **Home** — five sample habits, three already done, progress card on top.
   Tap a circle on the right to log a habit; tap the card body for its detail.
3. **Habit Detail** — streak, best streak, completion rate, five-week heat map.
4. **"+"** — the create-habit form.
5. **Bottom bar** — Today, Stats, Settings, Profile.

---

## If something goes wrong

| Problem | Fix |
|---|---|
| `flutter: command not found` | Flutter's `bin` folder isn't on your `PATH` — reinstall and reopen the terminal |
| `No devices found` | Start an emulator, or just use `./run.sh chrome` |
| `Address already in use` | An old run is still going: `pkill -f "flutter run"`, then retry |
| `Waiting for another flutter command...` | `killall -9 dart` (macOS/Linux), then retry |
| Android licence errors | `flutter doctor --android-licenses`, accept all |
| Gradle fails with only a version number as the error | JDK too new for Gradle: `brew install --cask temurin@17` then `flutter config --jdk-dir "$(/usr/libexec/java_home -v 17)"` |
| Anything else | From `flutter_app/`: `flutter clean && flutter pub get`, then run again |

`flutter doctor -v` tells you exactly what your machine is missing.

**To reset the app to a fresh first launch:** uninstall it from the
emulator/phone, or in Chrome open DevTools → *Application* → *Clear site data*.

---

## After running `flutter create`

Regenerating the platform folders (see the Gradle troubleshooting note above)
also restores two things this project deliberately replaced:

```bash
cd flutter_app
rm -f test/widget_test.dart      # scaffold counter test; the real tests are in test/habit_test.dart
rm -rf .idea *.iml android/*.iml # per-machine IDE files
```

Leave `test/habit_test.dart` alone — that is the real test suite. Without the
first line, `flutter analyze` and `flutter test` both fail on a generated test
that references a `MyApp` class this project does not have.
