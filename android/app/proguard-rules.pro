# ============================================================
# Flutter Core - Must keep these or app will crash
# ============================================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class org.chromium.** { *; }

# Keep code that might be invoked via reflection / method channels
-keep class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class * extends io.flutter.plugin.common.EventChannel$StreamHandler { *; }

# ============================================================
# Ignore missing Play Store Split/Deferred classes
# ============================================================
-dontwarn com.google.android.play.core.**

# ============================================================
# Firebase - Keep all Firebase classes readable
# (obfuscated Firebase = Play Protect suspicious flag)
# ============================================================
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ============================================================
# Supabase / OkHttp / Networking
# Keep networking classes readable so Play Protect can verify
# no malicious data exfiltration is happening
# ============================================================
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**

# ============================================================
# Anonymous Posting Feature
# IMPORTANT: Keep these readable so Play Protect does NOT
# misidentify identity-masking as spyware/stalkerware behavior.
# Obfuscated "anonymous" + "identity" code = spyware pattern!
# ============================================================
-keepclassmembers class ** {
    boolean isAnonymous;
    boolean is_anonymous;
    java.lang.String anonymous;
    java.lang.String identity;
}

# ============================================================
# JSON / Data Models
# Keep model class names so JSON parsing works correctly
# ============================================================
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keep class * implements java.io.Serializable { *; }

# ============================================================
# Image / Media libraries
# ============================================================
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# ============================================================
# Kotlin Coroutines
# ============================================================
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**
