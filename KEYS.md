# Keys and Signing - CRITICAL

## THE RULE
Settings.Secure.ANDROID_ID = f(hardware, signing cert, applicationId, user).

Your Java app and this Flutter app MUST share:
1. Same applicationId: com.example.dsjvastroapp
2. Same release signing keystore

If either changes, EVERY existing user's ANDROID_ID changes.
Server whitelist stops matching. All users locked out.

## Checklist before release
[ ] applicationId = com.example.dsjvastroapp
[ ] android/key.properties -> ORIGINAL release .jks
[ ] Side-by-side test: old APK "Key" == new APK "Key"

## key.properties format
    storePassword=YOUR_STORE_PASSWORD
    keyPassword=YOUR_KEY_PASSWORD
    keyAlias=YOUR_KEY_ALIAS
    storeFile=/absolute/path/to/your-existing-release-key.jks

## If IDs don't match
Ship with authEndpoint temporarily pointed at athenticate_mobile_v2.php
that accepts BOTH old and new IDs for a 30-day grace period, then retire.
