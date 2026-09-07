# How to run Loopwell

**Loopwell — a daily habit tracker.** ICT725 Assessment 3, Pradeep Bhandari.

This guide gets the app running from nothing, on any machine. Pick the section
that matches how you want to run it. **The fastest option is [Chrome](#option-a--chrome-fastest-2-minutes)** — it needs no
emulator and no Android Studio.

There is **no backend, no login, no API key and no config file**. The app runs
offline and creates its own sample data on first launch.

---

## Step 0 — Install Flutter (once)

Skip this if `flutter --version` already prints a version.

| OS | Command |
|---|---|
| **macOS / Linux** | Download from <https://docs.flutter.dev/get-started/install>, unzip, then add `<unzipped>/flutter/bin` to your `PATH` |
| **macOS (Homebrew)** | `brew install --cask flutter` |
| **Windows** | Download the zip from <https://docs.flutter.dev/get-started/install/windows>, unzip to `C:\src\flutter`, add `C:\src\flutter\bin` to Path |

Then confirm:

```bash
flutter --version
```

This project was built and verified on **Flutter 3.47.2 / Dart 3.13.2 (stable)**.
Any Flutter 3.27 or newer should work.

---

## Step 1 — Get the code

```bash
git clone https://github.com/Sapun2/loopwell.git
cd loopwell/flutter_app
flutter pub get
```

> **Note the `cd`.** The Flutter project lives in the `flutter_app/`
> subfolder, not at the repository root. Every command below is run from
> inside `flutter_app/`.

---

## Option A — Chrome (fastest, ~2 minutes)

No emulator, no Android Studio, no Xcode.

```bash
flutter run -d chrome
```

Chrome opens with the app running. To force a specific port:

```bash
flutter run -d chrome --web-port 8787
```

> On macOS, avoid port 5000 — the AirPlay Receiver already uses it.

**Tip:** for a realistic phone view, open Chrome DevTools (`F12` or
`Cmd+Option+I`) and click the device-toolbar icon to switch to a phone frame.

---

## Option B — Android emulator

This is the option to use for the in-class demonstration.

1. Install **Android Studio** from <https://developer.android.com/studio>.
2. Open it, then go to **More Actions → SDK Manager** and make sure the Android
   SDK and *Android SDK Command-line Tools* are installed.
3. Go to **More Actions → Virtual Device Manager → Create Device**. Pick any
   phone (Pixel 7 is a good default), download a system image, and finish.
4. Press ▶ to start the emulator and wait for the home screen.
5. Accept the SDK licences once:

   ```bash
   flutter doctor --android-licenses
   ```

6. With the emulator running:

   ```bash
   flutter devices     # confirm the emulator is listed
   flutter run
   ```

If `flutter run` cannot decide which device to use, name it explicitly:

```bash
flutter run -d emulator-5554
```

---

## Option C — iOS simulator (macOS only)

Requires the full **Xcode** from the Mac App Store — the Command Line Tools
alone are not enough.

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
open -a Simulator
flutter run
```

---

## Option D — A real phone

**Android:** enable *Developer options* → *USB debugging* on the phone, plug it
in, accept the debugging prompt, then `flutter run`.

**iOS:** plug the phone in, open `flutter_app/ios/Runner.xcworkspace` in Xcode,
set a Signing Team under *Signing & Capabilities*, then `flutter run`.

---

## Option E — Desktop

```bash
flutter run -d macos      # needs full Xcode
flutter run -d windows    # needs Visual Studio with the C++ desktop workload
flutter run -d linux      # needs clang, cmake, ninja-build, libgtk-3-dev
```

---

## Building a shareable app file

```bash
flutter build apk --release        # build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release  # for the Play Store
flutter build web --release        # build/web/ — any static host
flutter build ios --release        # needs a signing certificate
```

The `.apk` can be emailed or copied to any Android phone and installed directly
(the phone will ask permission to install from an unknown source).

---

## Checking the project is healthy

```bash
flutter analyze   # expected: "No issues found!"
flutter test      # expected: "All tests passed!" (15 tests)
```

---

## What you should see

1. **Onboarding** — three indigo slides. *Skip*, or *Next* through to *Get Started*.
2. **Home (Today)** — five sample habits, three already done today, with a
   progress card at the top. Tap a circle on the right of any card to log it;
   tap the card body to open its detail.
3. **Habit Detail** — streak, best streak, completion rate, and a five-week heat map.
4. **"+" button** — the create-habit form.
5. **Bottom navigation** — Today, Stats, Settings, Profile.

Sample habits with history are seeded on first launch so nothing is empty.
Everything is saved on the device and survives restarting the app.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `flutter: command not found` | Flutter's `bin` folder is not on your `PATH` — redo Step 0 |
| `No devices found` | Start an emulator/simulator first, or use `flutter run -d chrome` |
| `Address already in use` on web | Another process holds the port: `flutter run -d chrome --web-port 8787` |
| `Waiting for another flutter command to release the startup lock` | `killall -9 dart` (macOS/Linux), then retry |
| Android build fails on licences | `flutter doctor --android-licenses` and accept all |
| Anything unexplained | `flutter clean && flutter pub get`, then run again |

Run `flutter doctor -v` for a full diagnosis of what your machine is missing.

---

## Resetting the app's data

The app stores habits on the device. To get back to a fresh first launch:

- **Emulator/phone:** uninstall and reinstall the app.
- **Chrome:** open DevTools → *Application* → *Clear site data*, then reload.
