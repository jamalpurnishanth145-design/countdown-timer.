# Countdown Timer – Flutter Android App

## Build an APK on Windows

1. Install Flutter and Android Studio (Android SDK).
2. Open Command Prompt or PowerShell in this folder.
3. Run:

```powershell
flutter create . --platforms=android
flutter pub get
flutter build apk --release
```

4. Your APK will be created at:

`build\app\outputs\flutter-apk\app-release.apk`

5. Transfer that APK to your Android phone and install it. If Android asks, allow installation from this source.

## Features
- Custom hours, minutes and seconds
- Start, pause, resume and reset
- Circular progress display
- Quick presets: 1, 5, 10, 15 and 30 minutes
- Alarm alert when the timer reaches zero (while app is open)
- Saved timer history
- Light/dark theme toggle

Note: This is a foreground timer. For reliable ringing when the app is force-closed or the phone is restarted, a separate background notification/alarm implementation is needed.
