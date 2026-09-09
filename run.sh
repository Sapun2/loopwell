#!/usr/bin/env bash
# Loopwell — one-command launcher.
#   ./run.sh            pick the best device automatically
#   ./run.sh chrome     force the browser
#   ./run.sh android    force an Android emulator
set -e

cd "$(dirname "$0")/flutter_app"

# Put the Android tools on PATH ourselves. Relying on the shell profile fails
# in any terminal that was opened before setup wrote it.
for _sdk in "${ANDROID_HOME:-}" \
            "$(brew --prefix 2>/dev/null)/share/android-commandlinetools" \
            "$HOME/Library/Android/sdk"; do
  [ -n "$_sdk" ] && [ -d "$_sdk/platform-tools" ] || continue
  export ANDROID_HOME="$_sdk"
  export ANDROID_SDK_ROOT="$_sdk"
  export PATH="$_sdk/platform-tools:$_sdk/emulator:$_sdk/cmdline-tools/latest/bin:$PATH"
  break
done

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed, or not on your PATH."
  echo "Install it from https://docs.flutter.dev/get-started/install and try again."
  exit 1
fi

echo "==> Installing dependencies"
flutter pub get

WANT="${1:-auto}"

# The device id of the first fully-booted emulator, if any.
emulator_device() {
  adb devices 2>/dev/null | awk '/^emulator-/ && $2 == "device" { print $1; exit }'
}

# An emulator reports itself to adb long before Android has finished booting,
# so presence alone is not enough — wait for sys.boot_completed.
wait_for_emulator() {
  printf "    waiting for it to boot"
  for _ in $(seq 1 90); do
    DEVICE="$(emulator_device)"
    if [ -n "$DEVICE" ] && \
       [ "$(adb -s "$DEVICE" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; then
      echo " ready"
      return 0
    fi
    printf "."
    sleep 3
  done
  echo
  return 1
}

# Always pass -d. Without it, Flutter prompts to choose between macOS, Chrome
# and the emulator, and picking a desktop target fails without Xcode.
run_on_emulator() {
  DEVICE="$(emulator_device)"
  if [ -z "$DEVICE" ]; then
    echo "    emulator booted but adb cannot see it."
    return 1
  fi
  echo "==> Running on $DEVICE"
  exec flutter run -d "$DEVICE"
}

launch_android() {
  # Already running and fully booted?
  if [ -n "$(emulator_device)" ]; then
    echo "==> Using the running Android emulator"
    run_on_emulator
  fi

  # Configured in Flutter (the usual case when Android Studio is installed).
  EMU=$(flutter emulators 2>/dev/null | grep -iE "•.*android" | head -1 | awk '{print $1}')
  if [ -n "$EMU" ]; then
    echo "==> Starting Android emulator: $EMU"
    flutter emulators --launch "$EMU" >/dev/null 2>&1 || true
    wait_for_emulator && run_on_emulator
  fi

  # Fall back to the SDK's emulator binary directly. Flutter does not always
  # enumerate AVDs when only the command-line tools are installed.
  EMU_BIN="$(command -v emulator || echo "${ANDROID_HOME:-$HOME/Library/Android/sdk}/emulator/emulator")"
  if [ -x "$EMU_BIN" ]; then
    AVD=$("$EMU_BIN" -list-avds 2>/dev/null | head -1)
    if [ -n "$AVD" ]; then
      echo "==> Starting Android emulator: $AVD"
      "$EMU_BIN" -avd "$AVD" >/dev/null 2>&1 &
      wait_for_emulator && run_on_emulator
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
