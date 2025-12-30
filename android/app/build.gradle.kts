import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties for RELEASE signing
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    throw GradleException(
        "key.properties not found at: ${keystorePropertiesFile.absolutePath}. " +
                "Create android/key.properties for release signing."
    )
}

android {
    namespace = "com.muhammetvural.kpsstekrartakibi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"]?.toString()
                ?: throw GradleException("Missing 'storeFile' in key.properties")

            storeFile = file(storeFilePath)
            storePassword = keystoreProperties["storePassword"]?.toString()
                ?: throw GradleException("Missing 'storePassword' in key.properties")
            keyAlias = keystoreProperties["keyAlias"]?.toString()
                ?: throw GradleException("Missing 'keyAlias' in key.properties")
            keyPassword = keystoreProperties["keyPassword"]?.toString()
                ?: throw GradleException("Missing 'keyPassword' in key.properties")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.muhammetvural.kpsstekrartakibi"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // IMPORTANT: Release must be signed with RELEASE keystore (not debug)
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}