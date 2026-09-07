@echo off
REM Loopwell - one-command launcher for Windows.
REM   run.bat           pick the best device automatically
REM   run.bat chrome    force the browser
cd /d "%~dp0flutter_app"

where flutter >nul 2>&1
if errorlevel 1 (
  echo Flutter is not installed, or not on your PATH.
  echo Install it from https://docs.flutter.dev/get-started/install and try again.
  exit /b 1
)

echo ==^> Installing dependencies
call flutter pub get

if /i "%1"=="chrome" (
  echo ==^> Launching in Chrome
  call flutter run -d chrome
  exit /b 0
)

flutter devices 2>nul | findstr /i "emulator-" >nul
if not errorlevel 1 (
  echo ==^> Using the running Android emulator
  call flutter run
  exit /b 0
)

echo ==^> No emulator running - launching in Chrome instead
echo     ^(start an emulator in Android Studio first for an emulator demo^)
call flutter run -d chrome
