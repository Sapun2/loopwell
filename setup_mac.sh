#!/usr/bin/env bash
# Loopwell — one-time setup for a fresh Mac.
#
# Installs Flutter and the Android SDK, creates an emulator, and leaves the
# machine ready for ./run.sh android. Safe to re-run: every step is skipped
# if it is already done.
#
# Deliberately uses the Android command-line tools rather than Android
# Studio: there is no GUI wizard to click through, which matters over a
# remote desktop connection.
set -euo pipefail

AVD_NAME="Loopwell"
API="35"

say()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[33m    %s\033[0m\n' "$*"; }

# --- Apple Silicon and Intel need different system images -----------------
case "$(uname -m)" in
  arm64)  ABI="arm64-v8a" ;;
  x86_64) ABI="x86_64" ;;
  *) echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac
say "Detected $(uname -m) — using the $ABI system image"

# --- Homebrew -------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  say "Installing Homebrew (it will ask for your password)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$p" ] && eval "$("$p" shellenv)"
  done
else
  say "Homebrew already installed"
fi

BREW_PREFIX="$(brew --prefix)"

# --- Flutter --------------------------------------------------------------
if command -v flutter >/dev/null 2>&1; then
  say "Flutter already installed — $(flutter --version 2>/dev/null | head -1)"
else
  say "Installing Flutter (large download, please wait)"
  brew install --cask flutter
fi

# --- Android SDK ----------------------------------------------------------
export ANDROID_HOME="$BREW_PREFIX/share/android-commandlinetools"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

if [ -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
  say "Android command-line tools already installed"
else
  say "Installing the Android command-line tools"
  brew install --cask android-commandlinetools
fi

export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

say "Installing the Android platform, emulator and system image (a few GB)"
sdkmanager --install \
  "platform-tools" \
  "emulator" \
  "platforms;android-$API" \
  "system-images;android-$API;google_apis;$ABI"

say "Accepting the Android SDK licences"
yes | sdkmanager --licenses >/dev/null 2>&1 || true

# --- Emulator -------------------------------------------------------------
if avdmanager list avd 2>/dev/null | grep -q "Name: $AVD_NAME"; then
  say "Emulator '$AVD_NAME' already exists"
else
  say "Creating the '$AVD_NAME' emulator"
  echo "no" | avdmanager create avd \
    -n "$AVD_NAME" \
    -k "system-images;android-$API;google_apis;$ABI" \
    -d "pixel_7"
fi

# --- Point Flutter at the SDK --------------------------------------------
say "Pointing Flutter at the Android SDK"
flutter config --android-sdk "$ANDROID_HOME" >/dev/null

# --- Make the environment permanent --------------------------------------
SHELL_RC="$HOME/.zshrc"
if ! grep -q "ANDROID_HOME=$ANDROID_HOME" "$SHELL_RC" 2>/dev/null; then
  say "Adding the Android SDK to $SHELL_RC"
  {
    echo ''
    echo '# Android SDK (added by Loopwell setup_mac.sh)'
    echo "export ANDROID_HOME=\"$ANDROID_HOME\""
    echo 'export ANDROID_SDK_ROOT="$ANDROID_HOME"'
    echo 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"'
  } >> "$SHELL_RC"
else
  say "$SHELL_RC already configured"
fi

say "Checking the toolchain"
flutter doctor || true

cat <<EOF

------------------------------------------------------------------
Setup complete.

Open a NEW terminal window (so the PATH changes take effect), then:

    cd "$(cd "$(dirname "$0")" && pwd)"
    ./run.sh android

That boots the '$AVD_NAME' emulator and launches Loopwell on it.
The very first Android build downloads Gradle and takes a few minutes;
every run after that takes seconds.

If the emulator is too slow over a remote desktop connection, use:

    ./run.sh chrome
------------------------------------------------------------------
EOF
