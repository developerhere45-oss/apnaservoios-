# ApnaServo iOS production-readiness audit

Audit date: 2026-08-12

## Fixed

- Removed seeded demo bookings and local fake-success booking behavior.
- Added a real booking details form; a booking is shown only after backend confirmation.
- Reuses a stable per-attempt booking request ID so safe retries use the backend's existing idempotency support.
- Prevents duplicate refresh, booking, partner-action, and chat-send interactions while work is in flight.
- Added partner accept/reject controls backed by the existing protected API routes.
- Chat is available only after assignment, orders and deduplicates messages, marks them seen, and performs one bounded foreground subscription using eight-second reconciliation polling.
- Cancels replaced refresh/chat tasks and removes chat polling when the screen disappears or the role changes.
- Added request/resource timeouts, connectivity waiting, sanitized server errors, cancellation handling, response validation, and request correlation IDs.
- Empty, loading, error, retry, pull-to-refresh, and app-reactivation refresh states now exist for the implemented booking lists.
- Persists the selected role and moves the temporary developer token from UserDefaults to the iOS Keychain.
- Uses `NavigationStack`, data-driven chat navigation, guarded modal dismissal during booking submission, adaptive grids/stacks, Dynamic Type fonts, and keyboard-safe SwiftUI composition.
- Added the missing service categories exposed by the brief to the shared service catalog.

## Remaining

- Firebase Auth/Google Sign-In, token refresh, logout, account recovery, and authenticated session restoration are not integrated. The token field remains a developer-only bridge.
- The repository has no notification/deep-link router, tabs, location picker, partner quotation UI, call UI, cancellation UI, completion/review UI, profile flow, analytics, Crashlytics, or Firebase configuration.
- Chat uses reconciliation polling because the existing Socket.IO backend is not connected to this native client. True realtime reconnect behavior remains unimplemented.
- Failed-message retry UI and durable offline outbox storage are not implemented.
- Partner online/offline toggle is still local UI state because no backend availability contract is exposed here.
- Category-specific booking forms and validation are not present.
- No iOS test target exists in the Xcode project.

## High risk

- Authentication is launch-blocking: shipping a manual bearer-token input would be insecure and unusable.
- End-to-end booking lifecycle after creation is incomplete in the native UI.
- Push notifications and deep links are absent, so incoming jobs and booking updates cannot be relied upon when the app is backgrounded.
- No production crash/error telemetry exists in this target.
- Release compilation, signing, device behavior, accessibility, network conditioning, and lifecycle tests require macOS/Xcode and real Firebase accounts.

## Backend

- Protected booking/chat routes use Firebase middleware and load records through the authenticated customer/partner identity.
- Backend controllers already implement atomic/idempotent booking acceptance, booking creation keyed by `bookingCode`, and chat send keyed by `(bookingId, senderRole, clientMessageId)`.
- Chat reads are bounded to 150 messages (80 by default) and support a `before` cursor, but the iOS client currently loads only the newest page.
- Customer booking history is capped at 500 rather than cursor-paginated; partner queries also require production query-plan review.
- Schema audit reported zero missing declared indexes. Deployed indexes, Firebase/database rules, environment secrets, quotas, and production authorization were not verified from this Windows workspace.

## Scalability

- Client-side duplicate suppression, request cancellation, bounded chat reads, and a single chat polling task reduce avoidable load.
- The local synthetic scale model flagged notification fanout (113,000 notifications at configured concurrency 8) as a bottleneck and recommends a durable Redis-backed queue, multiple backend instances, and a Socket.IO Redis adapter.
- Capacity for 10,000 users is **not verified**. The simulation does not exercise the deployed database/network and must not be treated as a load test.

## Tested

- Static audit of every Swift source and Xcode project configuration.
- Contract comparison against the local Express booking/chat routes and controllers.
- Backend JavaScript syntax check, 10 lifecycle/idempotency checks, schema index audit, eight static security checks, and synthetic scale simulation all completed successfully.
- Repository scans for stale call sites, merge markers, debug fallbacks, unsafe force casts, and project-file consistency.

Not tested here:

- Xcode Debug/Release compilation (Xcode is not available on Windows).
- iPhone simulator or physical-device flows.
- Live Firebase authentication, deployed backend calls, push delivery, realtime sockets, or Crashlytics delivery.

## Required launch test matrix

Run on at least an iPhone SE-size simulator, a current Pro-size simulator, and one physical iPhone:

- Authentication: sign-in, invalid credentials, expiry/refresh, logout, cold restoration, offline startup.
- Booking: create, duplicate tap, timeout/retry, cancel, accept/reject, every valid status transition, kill/relaunch.
- Chat: send/receive, duplicate retry, pagination, offline recovery, background/foreground, keyboard and long messages.
- Navigation: booking sheet, chat push/back/swipe-back, notification deep link, role/tab switching, state restoration.
- UI/accessibility: largest Dynamic Type, VoiceOver, long localized content, light/dark appearance, rotation where enabled.
- Operations: Release archive, signing, production API environment, Crashlytics test crash/nonfatal, analytics validation.

## Final status

**NOT PRODUCTION READY**

The implemented scaffold is safer and no longer reports fake backend success, but launch-critical authentication, full booking lifecycle, true realtime/background delivery, telemetry, native tests, and device/Release verification remain incomplete.
