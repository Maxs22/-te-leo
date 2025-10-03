import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    kotlin("plugin.serialization") version "2.1.0"
}

// Cargar configuración de signing desde key.properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.teleo.te_leo"
    compileSdk = 36  
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Habilitar core library desugaring para flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }
    
    // Suprimir warnings de Java obsoletos
    lint {
        disable += setOf("ObsoleteSdkVersion")
        checkReleaseBuilds = false
        abortOnError = false
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.teleo.te_leo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36 
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Configuración de firma para release
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Optimización de release: habilitar R8 y shrinkResources
            isMinifyEnabled = true
            isShrinkResources = true
            
            // Configuración de ProGuard/R8 con reglas por defecto + archivo local
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Configuración adicional para optimización
            // ndk {
            //     debugSymbolLevel = "NONE"
            // }
            
            // Firma de release configurada
            signingConfig = signingConfigs.getByName("release")
        }
        
        debug {
            // Deshabilitar optimizaciones en debug para desarrollo más rápido
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    // Core library desugaring para flutter_local_notifications - actualizado a versión requerida
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
