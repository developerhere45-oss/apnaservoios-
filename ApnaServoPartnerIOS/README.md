# ApnaServoPartnerIOS

Native SwiftUI partner app recreated from the Android Partner App.

## Open

Open `ApnaServoPartnerIOS.xcodeproj` on macOS in Xcode, select the `ApnaServoPartnerIOS` target, set signing, then run on an iPhone simulator/device.

## Included

- Partner login/register profile flow
- Dashboard with online toggle, stats, new/active bookings
- Request accept/reject and job lifecycle updates
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
- Add Firebase iOS packages and connect Firebase Auth token to `PartnerAppStore.authToken`.
- Enable APNs/push notification capability.
- Add Socket.IO Swift package for native realtime events.
- Add Vision/ML Kit equivalent if production-grade liveness detection is required.
- Add PhotosUI/DocumentPicker UI to call `APIClient.uploadDocument`.
