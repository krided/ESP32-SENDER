# E46 Speeduino Flutter App (Windows-friendly)

This Flutter app connects to your ESP32 via BLE and mirrors your web UI design. Build iOS on Codemagic from Windows.

## 1) Install Flutter on Windows
- Download: https://docs.flutter.dev/get-started/install/windows
- Add Flutter to PATH
- In PowerShell:
```powershell
flutter --version
flutter doctor
```
Fix any issues reported by `flutter doctor`.

## 2) Get dependencies
```powershell
cd flutter-app
flutter pub get
```

## 3) Run (optional Android test)
If you have an Android device/emulator:
```powershell
flutter run
```
The app UI and BLE logic are identical on iOS/Android.

## 4) Connect to ESP32
- ESP32 advertises as `E46 Speeduino`
- Service: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- Characteristic: `beb5483e-36e1-4688-b7f5-ea07361b26a8`
- App auto-scans, connects, and subscribes to JSON notifications

## 5) Build iOS with Codemagic (no Mac needed)
1. Push this repo (or only `flutter-app/`) to GitHub
2. Sign in to https://codemagic.io and add the repo
3. Codemagic detects `codemagic.yaml`
4. In workflow settings (UI), add iOS code signing (Apple ID, certificates, provisioning profile)
5. Start build → Download `.ipa` artifact when finished

### iPhone install without Developer Program
- Use Sideloadly or AltStore on Windows to install the `.ipa`
- Or install to TestFlight/App Store with a paid developer account

## 6) Customization
- Colors/UI: edit `lib/main.dart`, `lib/ui/widgets/*`
- BLE UUIDs/name: edit `lib/ble/ble_manager.dart`
- Thresholds are sent from ESP32; UI highlights when exceeded

## Notes
- `flutter_reactive_ble` handles BLE on both iOS and Android
- `codemagic.yaml` injects Bluetooth usage descriptions into `Info.plist` during build
- Minimum iOS version set to 15.0 (adjust in `codemagic.yaml`)
