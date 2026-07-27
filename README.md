# ApnaServo iOS

Native SwiftUI iOS projects for ApnaServo, packaged at repo root so a Mac can pull the same Git repo and open the Xcode projects directly.

## Projects

```text
apnaservo-ios/
  ApnaServoUserIOS/
    ApnaServoUserIOS.xcodeproj
    ApnaServoUserIOS/
  ApnaServoPartnerIOS/
    ApnaServoPartnerIOS.xcodeproj
    ApnaServoPartnerIOS/
```

## Run On Mac

1. Pull the latest repo on the Mac.
2. Open one of these projects in Xcode:

```bash
open ApnaServoUserIOS/ApnaServoUserIOS.xcodeproj
open ApnaServoPartnerIOS/ApnaServoPartnerIOS.xcodeproj
```

3. Select the app target.
4. Set your Apple Developer Team in `Signing & Capabilities`.
5. Add the correct `GoogleService-Info.plist` and Firebase iOS packages before a Release build.
6. Enable Push Notifications and Background Modes for remote notifications.
7. Choose an iPhone simulator or device and press Run.

## Current Scope

- Both apps use SwiftUI and the production ApnaServo API URL.
- Booking, profile, notification, payment, quote, review, chat, partner status, Laundry owner and Laundry staff calls use the backend endpoints shared with Android.
- Debug builds can use the backend's device-scoped development headers where enabled.
- Release builds require a real Firebase ID token. They do not use development authentication.
- Android raster resources used by iOS are bundled under each target's `ImportedAndroidAssets`.

## Included

- Customer app: splash, login, location gate, home, service categories, detail, booking details, date/time picker, address entry, confirmation, finding partner, partner assigned, active tracking, booking history, notifications, profile, support chat, booking chat, and commercial service screens.
- Partner app: role-based dashboard and permissions, online toggle, request accept/reject, job lifecycle updates, Laundry staff management/assignment, location heartbeat, bookings, earnings, notifications, support, chat, protected call and no-response reporting.
- Imported Android raster assets for visual parity.
