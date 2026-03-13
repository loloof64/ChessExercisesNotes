# flutter_web_auth_2
-keep class com.linusu.flutter_web_auth_2.** { *; }

# oauth2_client – keep all model/token classes used via reflection or JSON
-keep class com.tetra.oauth2_client.** { *; }
-keepattributes *Annotation*
-keepattributes Signature

# Keep Dart/Flutter plugin entry points
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }

# Prevent R8 from stripping JSON-serialised model fields
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# OkHttp / HTTP clients (used by flutter_web_auth_2 internally)
-dontwarn okhttp3.**
-dontwarn okio.**

# Flutter references Play Core for deferred components (split APKs) but we
# don't use the Play Store / deferred components — suppress missing-class errors.
-dontwarn com.google.android.play.core.**
