# ApnaServo User iOS

Native SwiftUI customer app for ApnaServo.

The Partner iOS app is maintained separately in
[apnaservopartnerios](https://github.com/developerhere45-oss/apnaservopartnerios).

```text
apnaservoios-/
  ApnaServoUserIOS/
    ApnaServoUserIOS.xcodeproj
    ApnaServoUserIOS/
```

## Run On Mac

1. Pull the latest repo on the Mac.
2. Open the User project in Xcode:

```bash
open ApnaServoUserIOS/ApnaServoUserIOS.xcodeproj
```

3. Select the app target.
4. Set your Apple Developer Team in `Signing & Capabilities`.
5. Let Xcode resolve the Firebase Swift packages.
6. Enable Push Notifications and Background Modes for remote notifications.
7. Choose an iPhone simulator or device and press Run.

## Current Scope

- The User app uses SwiftUI and the production ApnaServo API URL.
- Booking, profile, notification, payment, quote, review and chat calls use the backend endpoints shared with Android.
- Debug builds can use the backend's device-scoped development headers where enabled.
- Release builds require a real Firebase ID token. They do not use development authentication.
- Android raster resources used by iOS are bundled under `ImportedAndroidAssets`.

## Included

- Customer app: splash, login, location gate, home, service categories, detail, booking details, date/time picker, address entry, confirmation, finding partner, partner assigned, active tracking, booking history, notifications, profile, support chat, booking chat, and commercial service screens.
- Imported Android raster assets for visual parity.
