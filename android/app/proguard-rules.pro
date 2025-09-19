# Te Leo ProGuard Configuration
# Optimizaciones y ofuscación para reducir el tamaño de la APK

# Configuraciones básicas de Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Mantener clases de GetX
-keep class com.google.gson.** { *; }
-keep class get.** { *; }
-keepclassmembers class * extends get.GetxController {
    <methods>;
}

# Google ML Kit Text Recognition
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# Flutter TTS
-keep class com.tundralabs.fluttertts.** { *; }
-dontwarn com.tundralabs.fluttertts.**

# SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Package Info Plus
-keep class io.flutter.plugins.packageinfo.** { *; }

# HTTP y networking
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# In-App Update
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Mantener enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Mantener anotaciones
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Mantener métodos nativos
-keepclasseswithmembernames class * {
    native <methods>;
}

# Mantener constructores por defecto para serialización
-keepclassmembers class * {
    public <init>();
}

# Optimizaciones específicas para Te Leo
-keep class com.teleo.te_leo.** { *; }

# Mantener clases de datos/modelos
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Optimizaciones de R8
-allowaccessmodification
-repackageclasses ''
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*

# Logging (remover en release)
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Dart/Flutter específico
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class androidx.lifecycle.** { *; }

# Mantener crashlytics si se usa en el futuro
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Configuración para reducir warnings
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn kotlin.jvm.internal.**
