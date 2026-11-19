# Setup

## Prerequisites
- Flutter 3.19+
- Your existing release keystore
- assets/logo.png (1024x1024, transparent)

## Steps
1. Replace assets/logo.png with your DSJV logo
2. Edit android/key.properties with your ORIGINAL keystore paths
3. flutter pub get
4. dart run flutter_launcher_icons
5. dart run flutter_native_splash:create
6. flutter run

## Verify device ID matches old app
Install OLD apk and NEW apk on same device.
Open each -> menu -> Help / Device Info -> compare "Key:" values.
They MUST be identical. If not, see KEYS.md.

## Build release
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
