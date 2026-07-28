# ---------------------------------------------------------------------
# ProGuard/R8 rules for release builds (minifyEnabled + shrinkResources).
#
# Flutter's own Gradle plugin already bundles a base rule set for the
# Flutter engine itself when minification is on, so this file only
# needs to cover things that engine-level ruleset doesn't know about:
# this app's specific plugins, and a couple of well-known Flutter
# release-build gotchas.
# ---------------------------------------------------------------------

# flutter_local_notifications registers broadcast receivers/services via
# reflection (see AndroidManifest.xml) as well as normal method calls.
# Without this, R8 can strip or rename members that are only referenced
# by the manifest, silently breaking scheduled notifications in release
# builds while working fine in debug.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# Preserve annotations/generics used by plugin serialization code
# (affects flutter_local_notifications' notification detail objects and
# any future Supabase model classes).
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Flutter's deferred-components support references Google Play Core
# classes even when the app doesn't use deferred components. Without
# this, R8 fails release builds with "missing classes" errors for
# com.google.android.play.core.* the moment minifyEnabled is turned on.
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
