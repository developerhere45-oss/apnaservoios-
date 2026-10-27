# Google sign-in release checklist

The app uses Firebase Authentication with Android Credential Manager. The
`app/google-services.json` supplied with this project belongs to
`com.apnaservo.partner`, so it must not be swapped with the user-app file.

Before testing or uploading a release, complete these Firebase Console steps:

1. In **Authentication → Sign-in method**, enable the **Google** provider and
   choose a support email.
2. In **Project settings → Your apps → ApnaServo Partner**, register the SHA-1
   and SHA-256 fingerprints for every signing key used to install the app:
   Android Studio debug key, the upload key, and the Google Play App Signing
   certificate. Download a fresh `google-services.json` afterwards and replace
   `app/google-services.json`.
3. Confirm the Android package is exactly `com.apnaservo.partner`. Do not
   create a separate OAuth client in code; the Google Services Gradle plugin
   generates `default_web_client_id` from the Web OAuth client in this file.
4. Build and install the same variant whose fingerprint was registered. A
   debug build signed by an unregistered debug key and a Play-installed build
   signed by the Play certificate both fail Google sign-in, commonly with API
   10 / DEVELOPER_ERROR.

To print the local fingerprints, run:

```powershell
./gradlew signingReport
```

The app now checks for a missing/invalid generated Web client ID before opening
the account picker and reports a setup error instead of crashing. It also
preserves the Google-account selection flow through process recreation.
