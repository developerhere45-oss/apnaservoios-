# Keep stack traces actionable in Firebase Crashlytics while still allowing R8 to
# optimise app code. Firebase and AndroidX ship their own consumer rules.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Components instantiated by Android/Firebase from the manifest must retain
# their constructors in a minified release build.
-keep class * extends android.app.Application { <init>(); }
-keep class * extends android.app.Activity { <init>(); }
-keep class * extends com.google.firebase.messaging.FirebaseMessagingService { <init>(); }
-keep class androidx.core.content.FileProvider { <init>(); }

# Socket.IO discovers transport implementations dynamically.
-keep class io.socket.** { *; }
-dontwarn okhttp3.**

# ---------------------------------------------------------------------------
# Razorpay Checkout.
# Checkout.preload(...) runs on the very first line of MainActivity.onCreate,
# so if R8 strips/obfuscates the SDK the app crashes on the splash screen before
# any UI loads. Razorpay relies heavily on reflection and annotation processing,
# so its classes and annotations must be kept and its optional deps ignored.
-keep class com.razorpay.** { *; }
-keep interface com.razorpay.** { *; }
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-dontwarn com.razorpay.**
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
    public void onPayment*(...);
}
# Razorpay ships a proguard.annotation package it reads reflectively.
-keep class proguard.annotation.** { *; }
-keep @proguard.annotation.Keep class * { *; }
-keepclassmembers class * {
    @proguard.annotation.Keep *;
}
-dontwarn proguard.annotation.**

# ---------------------------------------------------------------------------
# Cashfree subscription checkout runs inside a WebView and exposes a JS bridge
# (AndroidCheckout.onResult). Keep the @JavascriptInterface methods reachable.
-keep class com.apnaservo.partner.CashfreeCheckoutActivity { *; }
-keepclassmembers class com.apnaservo.partner.CashfreeCheckoutActivity$* {
    @android.webkit.JavascriptInterface <methods>;
}

# ---------------------------------------------------------------------------
# Glide generates an API via annotation processing and loads modules reflectively.
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.module.AppGlideModule { <init>(...); }
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** { **[] $VALUES; public *; }
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**

# ---------------------------------------------------------------------------
# ZXing (QR generation) – keep core so MultiFormatWriter/BarcodeFormat survive.
-keep class com.google.zxing.** { *; }
-dontwarn com.google.zxing.**

# ---------------------------------------------------------------------------
# OkHttp / Okio optional platform classes referenced but not always present.
-dontwarn okio.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# ---------------------------------------------------------------------------
# Keep our own model/callback classes that may be reached reflectively by SDKs.
-keep class com.apnaservo.partner.** implements com.razorpay.PaymentResultWithDataListener { *; }
