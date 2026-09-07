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

launch_android() {
  # Already running?
  if flutter devices 2>/dev/null | grep -qi "emulator-"; then
    echo "==> Using the running Android emulator"
    exec flutter run
  fi
  # Not running, but one is configured — boot it and wait.
  EMU=$(flutter emulators 2>/dev/null | grep -iE "android" | head -1 | awk '{print $1}')
  if [ -n "$EMU" ]; then
    echo "==> Starting Android emulator: $EMU"
    flutter emulators --launch "$EMU" >/dev/null 2>&1 || true
    printf "    waiting for it to boot"
    for _ in $(seq 1 60); do
      if flutter devices 2>/dev/null | grep -qi "emulator-"; then echo " ready"; exec flutter run; fi
      printf "."; sleep 3
    done
    echo
    echo "    emulator did not come up in time."
  fi
  return 1
}

case "$WANT" in
  chrome) echo "==> Launching in Chrome"; exec flutter run -d chrome ;;
  android) launch_android || { echo "No Android emulator available. Create one in Android Studio (More Actions > Virtual Device Manager)."; exit 1; } ;;
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
