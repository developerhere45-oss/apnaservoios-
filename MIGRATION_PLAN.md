# ApnaServo Android to Native iOS Migration Plan

## Android Screens Found

### User App
- Splash / login / Google sign-in
- Home with banner, search, popular services, more services, latest booking footer
- All services with category chips
- Service detail
- Booking form with issue, address, GPS, date, time, service tier
- Booking confirmation and backend submission wait
- Partner assignment wait
- Track booking with timeline, chat, call, map/navigation, amount approval, counter offer
- My bookings / booking history
- Review dialog
- AI support chat and booking chat
- Notifications
- Profile, edit profile, saved address, settings, legal, logout, delete-account request

### Partner App
- Splash / login / register / Google sign-in
- Face verification intro/capture/complete
- Dashboard with online toggle, stats, new requests, active jobs
- Incoming booking popup/request detail
- Order detail and job lifecycle
- In-app map / external navigation
- Bookings list
- Earnings and statement PDF
- Notifications
- Side/profile menu
- Personal information
- Documents and Aadhaar last-4 verification
- My services, service radius, service area
- Settings, legal, account deletion
- Partner support chat and customer booking chat
- Protected call and no-response report

## API Endpoints Found

### User
- `POST /users/profile`
- `POST /users/fcm-token`
- `POST /users/delete-account-request`
- `GET /notifications?role=user`
- `PATCH /notifications/:id/read?role=user`
- `POST /bookings`
- `GET /bookings/:id`
- `PATCH /bookings/:id/status`
- `POST /bookings/:id/quote/counter`
- `POST /reviews/bookings/:id`
- `POST /bookings/:id/chat/monitor`
- `GET /bookings/:id/chat/messages`
- `POST /bookings/:id/chat/messages`
- `PATCH /bookings/:id/chat/seen`

### Partner
- `POST /partners/profile`
- `GET /partners/me`
- `POST /partners/fcm-token`
- `POST /partners/delete-account-request`
- `GET /notifications?role=partner`
- `PATCH /notifications/:id/read?role=partner`
- `POST /partners/online`
- `POST /partners/offline`
- `PATCH /partners/location`
- `GET /bookings/partner`
- `POST /bookings/:id/accept`
- `POST /bookings/:id/reject`
- `PATCH /bookings/:id/status`
- `GET /reviews/partner/me`
- `POST /reviews/:id/dispute`
- `POST /partners/verification`
- `POST /partners/documents`
- `POST /bookings/:id/calls`
- `POST /bookings/:id/no-response-report`
- `GET /partner/get-statement`
- Shared booking chat endpoints above

## Socket / Notification Events
- User listens for `booking:accepted`, `booking:status_update`, `booking:rejected`, `booking:chat_message`, `booking:chat_seen`.
- Partner listens for `booking:new_request`, `booking:accepted`, `booking:unavailable`, `booking:status_update`, `booking:rejected`, `booking:chat_message`, `booking:chat_seen`.
- Partner emits `partner:online`, `partner:location_update`, `partner:offline`.
- Android FCM channel is `booking_requests`; iOS equivalent is APNs + Firebase Messaging notification presentation.

## iOS Mapping
- Activity/programmatic Android UI -> SwiftUI route screens.
- Android state fields -> `UserAppStore` and `PartnerAppStore` `ObservableObject`.
- OkHttp backend clients -> `URLSession` API clients with bearer Firebase ID token.
- SharedPreferences/SecurePrefs -> `UserDefaults` for profile/local cache and Keychain-style `SecureStore` for token.
- Firebase FCM -> `UNUserNotificationCenter` + conditional Firebase Messaging hooks.
- Google Maps intent -> Apple Maps URL and SwiftUI Map for partner in-app navigation.
- ML Kit face liveness -> native iOS placeholder flow ready for Vision/Firebase package integration.

## iOS Projects Created
- `ApnaServoUserIOS/ApnaServoUserIOS.xcodeproj`
- `ApnaServoPartnerIOS/ApnaServoPartnerIOS.xcodeproj`

## Missing Assets / Config
- `GoogleService-Info.plist` for each bundle.
- Firebase iOS packages: FirebaseCore, FirebaseAuth, FirebaseMessaging, FirebaseStorage if direct storage upload is needed.
- APNs capability, APNs auth key/cert in Firebase, push notification entitlement.
- Google Sign-In URL schemes/client ID if Google login is required.
- Socket.IO Swift package if true socket events are preferred over polling fallback.
- Google Maps SDK key only if Apple Maps is not acceptable.
- Production AppIcon asset catalog and launch artwork.
