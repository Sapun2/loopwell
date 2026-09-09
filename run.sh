#!/usr/bin/env bash
# Loopwell — one-command launcher.
#   ./run.sh            pick the best device automatically
#   ./run.sh chrome     force the browser
#   ./run.sh android    force an Android emulator
set -e

cd "$(dirname "$0")/flutter_app"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed, or not on your PATH."
  echo "Install it from https://docs.flutter.dev/get-started/install and try again."
  exit 1
fi

echo "==> Installing dependencies"
flutter pub get

WANT="${1:-auto}"

wait_for_emulator() {
  printf "    waiting for it to boot"
  for _ in $(seq 1 90); do
    if flutter devices 2>/dev/null | grep -qi "emulator-"; then
      echo " ready"
      return 0
    fi
    printf "."
    sleep 3
  done
  echo
  return 1
}

launch_android() {
  # Already running?
  if flutter devices 2>/dev/null | grep -qi "emulator-"; then
    echo "==> Using the running Android emulator"
    exec flutter run
  fi

  # Configured in Flutter (the usual case when Android Studio is installed).
  EMU=$(flutter emulators 2>/dev/null | grep -iE "•.*android" | head -1 | awk '{print $1}')
  if [ -n "$EMU" ]; then
    echo "==> Starting Android emulator: $EMU"
    flutter emulators --launch "$EMU" >/dev/null 2>&1 || true
    wait_for_emulator && exec flutter run
  fi

  # Fall back to the SDK's emulator binary directly. Flutter does not always
  # enumerate AVDs when only the command-line tools are installed.
  EMU_BIN="$(command -v emulator || echo "${ANDROID_HOME:-$HOME/Library/Android/sdk}/emulator/emulator")"
  if [ -x "$EMU_BIN" ]; then
    AVD=$("$EMU_BIN" -list-avds 2>/dev/null | head -1)
    if [ -n "$AVD" ]; then
      echo "==> Starting Android emulator: $AVD"
      "$EMU_BIN" -avd "$AVD" >/dev/null 2>&1 &
      wait_for_emulator && exec flutter run
    fi
  fi

  echo "    no Android emulator could be started."
  return 1
}

case "$WANT" in
  chrome) echo "==> Launching in Chrome"; exec flutter run -d chrome ;;
  android) launch_android || { echo "No Android emulator available. Run ./setup_mac.sh to create one."; exit 1; } ;;
  auto)
    launch_android 2>/dev/null || true
    if flutter devices 2>/dev/null | grep -qiE "ios simulator"; then
      echo "==> Using the running iOS simulator"; exec flutter run
    fi
    echo "==> No emulator running — launching in Chrome instead"
    echo "    (for an emulator demo, run: ./run.sh android)"
    exec flutter run -d chrome
    ;;
  *) echo "Usage: ./run.sh [chrome|android]"; exit 1 ;;
esac
