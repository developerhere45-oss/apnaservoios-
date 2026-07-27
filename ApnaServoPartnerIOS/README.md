# ApnaServoPartnerIOS

Native SwiftUI partner app recreated from the Android Partner App.

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
- Protected call/no-response report hooks
- Booking chat and partner support chat
- URLSession API calls matching Android endpoints
- UserDefaults + Keychain-style storage
- Imported Android raster assets in `ImportedAndroidAssets`

## Required Config

- Add `GoogleService-Info.plist`.
- Add Firebase Core, Auth and Messaging packages and connect the Firebase ID token to `PartnerAppStore.authToken`.
- Enable APNs/push notification capability.
- Add Socket.IO Swift package for native realtime events.
- Add Vision/ML Kit equivalent if production-grade liveness detection is required.
- Add PhotosUI/DocumentPicker UI to call `APIClient.uploadDocument`.
- Cleaning Staff cannot be completed until Android/backend exposes a cleaning staff identity, assignment and status API. The current production contract exposes staff endpoints only for Laundry.
