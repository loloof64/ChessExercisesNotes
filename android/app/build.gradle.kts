import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing credentials from key.properties (not tracked by git)
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties().apply {
    if (keyPropertiesFile.exists()) load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.loloof64.chess_exercises_notes"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.loloof64.chess_exercises_notes"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties.getProperty("keyAlias") ?: ""
            keyPassword = keyProperties.getProperty("keyPassword") ?: ""
            storeFile = keyProperties.getProperty("storeFile")
                ?.let { file(it) }
            storePassword = keyProperties.getProperty("storePassword") ?: ""
        }
    }

    buildTypes {
        release {
            signingConfig = if (keyPropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
