# R8 keep rules. Flutter's own rules are injected by the Flutter Gradle
# plugin; these cover the SDKs known to break under shrinking.

# RevenueCat (purchases_flutter) reflects over its model classes.
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# Google Play Billing, reached via RevenueCat.
-keep class com.android.billingclient.** { *; }

# Play Core split-install classes referenced by Flutter's deferred
# components support even when unused.
-dontwarn com.google.android.play.core.**

# Firebase generally ships consumer rules; silence the leftovers.
-dontwarn com.google.firebase.**
