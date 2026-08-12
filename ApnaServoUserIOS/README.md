# ApnaServoUserIOS

Native SwiftUI customer app frontend recreated from the Android User App.

## Run On Mac

1. Pull this repo on the Mac.
2. Open the project in Xcode:

```bash
open ApnaServoUserIOS/ApnaServoUserIOS.xcodeproj
```

3. Select the `ApnaServoUserIOS` target.
4. Set your Apple Developer Team in `Signing & Capabilities`.
5. Choose an iPhone simulator or device and press Run.

## Included

- Uses SwiftUI and the shared ApnaServo production API.
- Android assets are copied into `ImportedAndroidAssets`.
- The user flow includes splash, login, location gate, home, all services, service detail, cleaning/laundry booking options, date/time, address, confirmation, finding partner, partner assigned, active tracking, cancellation, quote counter-offer, payment confirmation, review, history, notifications, profile, support, booking chat and commercial service screens.
- Booking, profile, notification, payment, quote, review and chat actions call the same backend routes used by Android.

## Production Config

- Add the correct `GoogleService-Info.plist`.
- Add Firebase Core, Auth and Messaging through Swift Package Manager.
- Exchange the backend OTP custom token with Firebase Auth and pass the resulting ID token to the store/API client.
- Enable APNs and upload the APNs key to Firebase.
- Release builds require Firebase authentication; device development headers are Debug-only.
