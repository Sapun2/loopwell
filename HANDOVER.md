# Running Loopwell on another Mac over AnyDesk

Step-by-step, for demonstrating the app on a second Mac you control remotely.

> **Do this at least a day before you present.** The one-time setup downloads
> several gigabytes and the first Android build takes a few minutes. None of it
> is hard, but none of it is fast either.

| Stage | Roughly how long |
|---|---|
| Connect over AnyDesk | 10 min (mostly macOS permissions) |
| Get the code onto that Mac | 1 min |
| Install Flutter + Android SDK + emulator | 30–60 min, mostly downloading |
| First `./run.sh android` | 5–10 min |
| Every run after that | Under a minute |

---

## Step 1 — Connect to the other Mac with AnyDesk

Do this part first, because macOS permissions catch almost everyone.

1. Install AnyDesk on **both** Macs from <https://anydesk.com/download>.
2. On the **remote** Mac (the one you'll be controlling), open AnyDesk and note
   the **9-digit address** shown at the top.
3. On the remote Mac, grant AnyDesk its macOS permissions —
   **System Settings → Privacy & Security** — and switch AnyDesk ON under
   **all four** of:
   - **Screen Recording** — without this you connect but see a black screen
   - **Accessibility** — without this you can see but cannot click
   - **Input Monitoring** — needed for the keyboard
   - **Full Disk Access** — needed for file transfer
4. **Quit and reopen AnyDesk** on the remote Mac. The permissions do not take
   effect until it restarts.
5. If nobody will be sitting at the remote Mac to accept your connection, set
   an unattended password on it: **AnyDesk → Settings → Security →
   Enable unattended access**.
6. From your Mac, enter the 9-digit address and connect.

**Make it usable before you go further** — AnyDesk → **Settings → Display**:
- Set **"Optimise reaction time"** (not "Optimise image quality")
- Turn **off** "Show remote cursor"

An Android emulator is a large area of constantly-changing pixels, which is the
worst case for remote desktop. These two settings make the difference between
usable and unusable.

---

## Step 2 — Get the code onto that Mac

**Do not copy files by hand.** The repository is public, so on the remote Mac
open Terminal (`Cmd+Space`, type "Terminal") and run:

```bash
cd ~/Desktop
git clone https://github.com/Sapun2/loopwell.git
cd loopwell
```

That is the whole transfer. It also means any fix you push later is one
`git pull` away on that machine.

<details>
<summary>If that Mac has no internet, or git is unavailable</summary>

Use AnyDesk's file transfer: in the session toolbar choose the **file transfer**
icon, send `Loopwell_Submission_Pradeep_Bhandari.zip` from your Desktop, then on
the remote Mac double-click the zip to unpack it. Everything below works the
same — just `cd` into the unzipped `Loopwell` folder instead.
</details>

---

## Step 3 — One-time setup on that Mac

From inside the folder you just cloned:

```bash
./setup_mac.sh
```

This installs Homebrew (if missing), Flutter, the Android SDK, and creates an
emulator called **Loopwell**. It detects Apple Silicon vs Intel and picks the
right system image automatically. It is safe to re-run — anything already
installed is skipped.

It will ask for your Mac password once (Homebrew needs it) and prints
`flutter doctor` at the end.

> **Why not Android Studio?** The script uses Android's command-line tools
> instead, so there is no graphical setup wizard to click through — which
> matters a lot over a laggy remote connection. If you'd rather use Android
> Studio, install it from <https://developer.android.com/studio> and create a
> Pixel device in **More Actions → Virtual Device Manager**; `./run.sh android`
> will find it either way.

**When it finishes, open a new Terminal window.** The script adds the Android
SDK to your `PATH`, and that only applies to new terminals.

---

## Step 4 — Run it on the emulator

In the new Terminal window:

```bash
cd ~/Desktop/loopwell
./run.sh android
```

That boots the emulator, waits for it, and installs the app. The first build
downloads Gradle and takes several minutes — this is normal and only happens
once. Later runs take seconds.

You should see the emulator window appear, then Loopwell open on its
onboarding screen.

---

## Step 5 — Before you demonstrate

1. **Reset the app to a clean state** so the dashboard looks its best —
   long-press Loopwell in the emulator, uninstall it, then `./run.sh android`
   again. That re-seeds five habits with three completed.
2. **Shrink the emulator window** to roughly phone size. A smaller window is
   dramatically smoother over AnyDesk than a full-size one.
3. Do one complete practice run through [`DEMO_SCRIPT.md`](DEMO_SCRIPT.md).
4. Leave the emulator **running**. Booting it costs a minute you don't want to
   spend in front of an audience.

---

## If the emulator is too slow over AnyDesk

This is the most likely problem on the day, and it is a connection limitation
rather than an app one. In order of preference:

1. **Shrink the emulator window.** Fewer pixels to encode. Biggest single win.
2. **AnyDesk → Display → Optimise reaction time**, and lower the colour quality.
3. **Present from the remote Mac's own screen** if you can, rather than through
   AnyDesk.
4. **Fall back to the browser:**
   ```bash
   ./run.sh chrome
   ```
   Same app, same codebase, up in about 20 seconds and far lighter over a
   remote connection. Press `F12`, click the device-toolbar icon, and pick a
   phone to keep it presenting as mobile. Say plainly that it's the web build
   of the same project — an app that runs everywhere is a point in your favour.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Black screen in AnyDesk | Screen Recording permission not granted, or AnyDesk not restarted after granting |
| Can see but cannot click | Accessibility permission not granted |
| `command not found: flutter` | You're in an old Terminal window — open a new one |
| `command not found: sdkmanager` | Same: open a new Terminal after `setup_mac.sh` |
| `No Android emulator available` | Re-run `./setup_mac.sh`; it will report what failed |
| Emulator boots but stays black | Give it 2–3 minutes on first boot; if still black, `emulator -avd Loopwell -gpu swiftshader_indirect` |
| Android licence errors | `flutter doctor --android-licenses` and accept all |
| Gradle build hangs | First build genuinely takes minutes. If it fails: `cd flutter_app && flutter clean && cd .. && ./run.sh android` |
| Anything else | `flutter doctor -v` reports exactly what's missing |

---

## Quick reference

Once set up, the whole thing is:

```bash
cd ~/Desktop/loopwell
./run.sh android      # emulator
./run.sh chrome       # browser fallback
git pull              # collect any later changes
```
