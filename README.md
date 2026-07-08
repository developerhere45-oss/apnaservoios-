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
  MIGRATION_PLAN.md
```

## Run On Mac

1. Pull the latest repo on the Mac.
2. Open one of these projects in Xcode:

```bash
open apnaservo-ios/ApnaServoUserIOS/ApnaServoUserIOS.xcodeproj
open apnaservo-ios/ApnaServoPartnerIOS/ApnaServoPartnerIOS.xcodeproj
```

3. Select the app target.
4. Set your Apple Developer Team in `Signing & Capabilities`.
5. Choose an iPhone simulator or device and press Run.

## Current User App Scope

The `ApnaServoUserIOS` app is frontend/UI only for this migration pass. It uses SwiftUI, imported Android assets, and local mock data for services, bookings, chat, notifications, profile, and commercial service flows.

Do not add Firebase/backend setup until the iOS visuals are approved against the Android User App. Existing API placeholder files are not called by the current SwiftUI user flow.

## Included

- Customer app: splash, login, location gate, home, service categories, detail, booking details, date/time picker, address entry, confirmation, finding partner, partner assigned, active tracking, booking history, notifications, profile, support chat, booking chat, and commercial service screens.
- Partner app: login/profile, online toggle, request accept/reject, job lifecycle updates, location heartbeat, bookings, earnings PDF download, documents/verification hooks, notifications, support chat, booking chat, protected call/no-response hooks.
- Imported Android raster assets for visual parity.

## Git Add

Because the repo has other pending changes, add only this package when committing the iOS work:

```bash
git add apnaservo-ios
git commit -m "Add ApnaServo iOS Swift projects"
git push
```
