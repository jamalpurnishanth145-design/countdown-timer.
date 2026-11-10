$ErrorActionPreference = 'Stop'
flutter create . --platforms=android
flutter pub get
flutter build apk --release
Write-Host ""
Write-Host "BUILD COMPLETE!"
Write-Host "APK: build\app\outputs\flutter-apk\app-release.apk"
