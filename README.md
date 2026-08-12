# ApnaServo iOS

SwiftUI iPhone/iPad scaffold for ApnaServo with both customer and partner modes in one app. This repository is not yet a production-complete application; see `PRODUCTION_READINESS.md` for the verified gaps and launch gate.

## Folder Map

```text
ios-app/
  ApnaServoIOS.xcodeproj        Xcode project to open on Mac
  ApnaServoIOS/
    App/                        App entry and config
    UserApp/                    Customer/User iOS screens
      UserAppView.swift
    PartnerApp/                 Service Partner iOS screens
      PartnerAppView.swift
    Views/                      Shared iOS views
      RootView.swift
      BookingChatView.swift
      SharedComponents.swift
    Models/                     Shared models
    Services/                   Backend API client
    Stores/                     App state
```

## Open on Mac

1. Copy this `ios-app` folder to a Mac.
2. Open `ApnaServoIOS.xcodeproj` in Xcode.
3. Select the `ApnaServoIOS` target.
4. In `Signing & Capabilities`, choose your Apple Developer Team.
5. Pick an iPhone simulator or connected iPhone and press Run.

## Backend

The app points to:

```text
https://apnaservobk-1.onrender.com/api
```

The backend requires Firebase ID tokens for protected APIs. For quick testing, open the app and paste a Firebase ID token in the token field. For production, add Firebase iOS SDK + Google Sign-In in Xcode and set `AppStore.authToken` from Firebase Auth.

## Included Screens

- Role switch: Customer or Partner
- Customer home with services and booking list
- Partner dashboard with jobs and status
- Shared booking chat screen using the backend chat APIs
- Loading, empty, error, retry, and duplicate-action protection for the implemented API flows

## Next Native iOS Steps

- Add `GoogleService-Info.plist` to the Xcode target.
- Add Firebase packages in Xcode:
  - `FirebaseAuth`
  - `FirebaseMessaging`
  - `GoogleSignIn`
- Replace the temporary token input with Google login.
- Add APNs capability for iOS push notifications.
