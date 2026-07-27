# ApnaServoPartnerIOS

Native SwiftUI Partner App recreated from the Android Partner App.

## Open

Open `ApnaServoPartnerIOS.xcodeproj` on macOS in Xcode, select the `ApnaServoPartnerIOS` target, set signing, then run on an iPhone simulator/device.

## Included

- Partner login/register profile flow
- Role-specific dashboards for individual, cleaning partner, Laundry owner and Laundry staff
- Permission-gated navigation, online toggle, stats and new/active bookings
- Request accept/reject and job lifecycle updates
- Laundry owner staff creation and order assignment
- Laundry staff session, assigned jobs and task status updates
- Partner GPS heartbeat and Apple Maps navigation
- Bookings, earnings, statement PDF download
- Notifications, profile tools, documents, verification, services/radius/area
- Protected call/no-response reporting
- Booking chat and partner support chat
- URLSession API calls matching Android endpoints
- UserDefaults + Keychain-style storage
- Imported Android raster assets bundled in `ImportedAndroidAssets`

## Xcode Setup

- Add `GoogleService-Info.plist` before enabling Firebase Auth/Messaging.
- Add Firebase iOS packages if push notifications and automatic Firebase ID tokens are required.
- Enable APNs/push notification capability for production booking alerts.
- Set the signing team on the `ApnaServoPartnerIOS` target.
- Backend base URL is in `ApnaServoPartnerIOS/App/AppConfig.swift`.

This Windows workspace cannot run `xcodebuild`; open the project on macOS and build from Xcode.
