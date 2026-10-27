# Apna Servo Partner Android

Open the `ApnaServoPartnerAndroid` folder in Android Studio.

Do not open `MainActivity.java` directly and do not choose the parent repository folder.

For Google sign-in setup and release certificates, see
[`GOOGLE_SIGN_IN_SETUP.md`](GOOGLE_SIGN_IN_SETUP.md).

This is a separate native Android partner app for Apna Servo. It shows incoming service bookings, lets the partner accept a request, and keeps accepted jobs in the ongoing jobs section.

Production builds must point to an HTTPS ApnaServo backend. Cleartext `http://` local fallback URLs are intentionally not used in the app.
