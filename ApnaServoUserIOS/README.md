# ApnaServoUserIOS

Native SwiftUI customer app frontend recreated from the Android User App.

## Run On Mac

1. Pull this repo on the Mac.
2. Open the project in Xcode:

```bash
open apnaservo-ios/ApnaServoUserIOS/ApnaServoUserIOS.xcodeproj
```

3. Select the `ApnaServoUserIOS` target.
4. Set your Apple Developer Team in `Signing & Capabilities`.
5. Choose an iPhone simulator or device and press Run.

## Current Scope

- Frontend/UI only.
- Uses SwiftUI and local mock/static data.
- Android assets are copied into `ImportedAndroidAssets`.
- The user flow includes splash, login, location gate, home, all services, service detail, booking details, date/time picker, address entry, confirmation, finding partner, partner assigned, active tracking, booking history, notifications, profile, support chat, booking chat, and commercial service screens.
- Existing API placeholder files are not called by the SwiftUI user flow.

## Notes

- Do not add Firebase/backend setup for this UI-only build.
- Backend wiring can be added later after the iOS visuals are approved against Android.
