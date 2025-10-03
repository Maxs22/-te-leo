# ProGuard rules for Te Leo - Más permisivo para evitar problemas en release

# Keep ALL Flutter plugins
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep Google ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep flutter_local_notifications classes
-keep class com.dexterous.** { *; }

# Keep TTS classes
-keep class com.tundralabs.** { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Flutter engine classes
-keep class io.flutter.** { *; }

# Keep GetX classes (usado para navegación y estado)
-keep class com.example.** { *; }

# Keep Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# Keep In-App Purchase classes
-keep class com.android.vending.billing.** { *; }
-keep class com.google.android.play.** { *; }

# Keep SQLite classes
-keep class org.sqlite.** { *; }
-keep class net.sqlcipher.** { *; }

# Keep SharedPreferences classes
-keep class android.content.SharedPreferences** { *; }

# Keep Image Picker classes
-keep class androidx.camera.** { *; }

# Keep URL Launcher classes
-keep class androidx.browser.** { *; }

# Keep WebView classes
-keep class android.webkit.** { *; }

# Suppress warnings
-dontwarn android.**
-dontwarn com.google.**
-dontwarn org.sqlite.**
-dontwarn dev.fluttercommunity.plus.packageinfo.**
-dontwarn io.flutter.plugins.sharedpreferences.**
-ignorewarnings

# Keep specific problematic classes
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# General Android optimizations - MENOS AGRESIVO
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 3
-allowaccessmodification
-dontpreverify

# Keep line numbers for debugging
-keepattributes SourceFile,LineNumberTable,*Annotation*,Signature,InnerClasses

# Keep all classes that might be accessed via reflection
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep all serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}