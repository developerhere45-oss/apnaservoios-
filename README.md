# ApnaServo User iOS

Native SwiftUI customer app for ApnaServo.

The production customer project is located at:

```text
ApnaServoUserIOS/ApnaServoUserIOS.xcodeproj
```

The Partner iOS app is maintained separately in
[apnaservopartnerios](https://github.com/developerhere45-oss/apnaservopartnerios).

## Run on Mac

1. Pull the latest repository.
2. Run `open ApnaServoUserIOS/ApnaServoUserIOS.xcodeproj`.
3. Select the app target and Apple Developer Team.
4. Let Xcode resolve Firebase Swift packages.
5. Enable Push Notifications and Background Modes for remote notifications.
6. Select an iPhone simulator or device and run.

## Current scope

- SwiftUI customer app using the production ApnaServo API.
- Booking, profile, notification, payment, quote, review and chat flows.
- Firebase authentication for Release builds.
- Imported Android raster resources for visual parity.

## Stabilization reference

`PRODUCTION_READINESS.md` records the latest local audit, validation results, risks,
and launch test matrix. The root-level `ApnaServoIOS` project is the earlier shared
customer/partner scaffold retained for compatibility; production customer work
should target `ApnaServoUserIOS`.
