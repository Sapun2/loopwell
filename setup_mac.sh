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

if [ "$(id -u)" -eq 0 ]; then
  cat <<'MSG'
This script must NOT be run with sudo or as root.

Homebrew refuses to install as root, and an Android SDK owned by root cannot
be used from your normal account. Run it again as yourself:

    ./setup_mac.sh

MSG
  exit 1
fi

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

# Homebrew does not add itself to the shell profile; without this a new
# Terminal cannot find brew, and therefore cannot find flutter.
BREW_BIN="$(command -v brew)"
ZPROFILE="$HOME/.zprofile"
if ! grep -q "brew shellenv" "$ZPROFILE" 2>/dev/null; then
  say "Adding Homebrew to $ZPROFILE"
  {
    echo ''
    echo '# Homebrew (added by Loopwell setup_mac.sh)'
    echo "eval \"\$($BREW_BIN shellenv)\""
  } >> "$ZPROFILE"
fi

# --- Flutter --------------------------------------------------------------
# The app uses RadioGroup (Flutter 3.32+) and CardThemeData / Color.withValues
# (3.27+), so a pre-existing but older Flutter will fail to compile. Check the
# version, not merely that the command exists.
MIN_FLUTTER="3.32.0"

version_lt() {
  [ "$1" = "$2" ] && return 1
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ]
}

if command -v flutter >/dev/null 2>&1; then
  FLUTTER_VER="$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')"
  say "Flutter $FLUTTER_VER already installed"
  if version_lt "$FLUTTER_VER" "$MIN_FLUTTER"; then
    warn "This project needs Flutter $MIN_FLUTTER or newer. Upgrading..."
    flutter upgrade --force || warn "flutter upgrade failed — upgrade it manually"
    FLUTTER_VER="$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')"
    if version_lt "$FLUTTER_VER" "$MIN_FLUTTER"; then
      echo
      echo "Flutter is still $FLUTTER_VER, which is too old to build this app."
      echo "Install a current Flutter from https://docs.flutter.dev/get-started/install"
      echo "and make sure it comes first on your PATH, then run this script again."
      exit 1
    fi
    say "Flutter is now $FLUTTER_VER"
  fi
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

# --- Java -----------------------------------------------------------------
# Gradle 8.x supports Java 17 to 23. On a machine with a newer JDK the Android
# build fails with the JDK version as the entire error message ("What went
# wrong: 26.0.1"), which is impossible to diagnose from the text alone. So it
# is not enough for *some* Java to be present: Gradle needs a compatible one.
#
# Flutter is pointed at JDK 17 through `flutter config --jdk-dir`, which is
# scoped to Flutter. JAVA_HOME is deliberately left alone so that whatever the
# rest of the machine uses is not disturbed.
# java_home -v 17 silently returns the newest JDK when 17 is absent, so the
# path it hands back must be verified rather than trusted.
jdk17_home() {
  local home
  home="$(/usr/libexec/java_home -v 17 2>/dev/null || true)"
  [ -n "$home" ] && [ -x "$home/bin/java" ] || return 1
  "$home/bin/java" -version 2>&1 | head -1 | grep -q '"17\.' || return 1
  echo "$home"
}

JDK_HOME="$(jdk17_home || true)"
if [ -z "$JDK_HOME" ]; then
  say "Installing Java 17 (Gradle does not support newer JDKs)"
  brew install --cask temurin@17
  JDK_HOME="$(jdk17_home || true)"
fi

if [ -n "$JDK_HOME" ]; then
  say "Using Java 17 for Gradle: $JDK_HOME"
  flutter config --jdk-dir "$JDK_HOME" >/dev/null 2>&1 || \
    warn "Could not set Flutter's JDK; run: flutter config --jdk-dir \"$JDK_HOME\""
else
  warn "No Java 17 found. If the Android build fails with a bare version"
  warn "number, install it with: brew install --cask temurin@17"
fi

# Licences first: sdkmanager otherwise stops mid-download to prompt for each
# one, which turns an unattended install into a babysitting job.
say "Accepting the Android SDK licences"
yes | sdkmanager --licenses >/dev/null 2>&1 || true

say "Installing the Android platform, emulator and system image (a few GB)"
yes | sdkmanager --install \
  "platform-tools" \
  "emulator" \
  "platforms;android-$API" \
  "system-images;android-$API;google_apis;$ABI"

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
