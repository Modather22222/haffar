plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Read local.properties for keystore config (written by CI or developer)
val localProps = java.util.Properties()
val localPropsFile = rootProject.file("local.properties")
if (localPropsFile.exists()) {
    localPropsFile.inputStream().use { localProps.load(it) }
}

android {
    namespace = "com.haffar.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // Signing config — production key from local.properties / CI env
    signingConfigs {
        create("release") {
            storeFile = localProps["key.store"]?.let { file(it) }
            storePassword = localProps["key.store.password"] as String?
            keyAlias = localProps["key.alias"] as String?
            keyPassword = localProps["key.key.password"] as String?
        }
    }

    defaultConfig {
        applicationId = "com.haffar.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = localProps["versionCode"]?.toIntOrNull()
            ?: System.getenv("VERSION_CODE")?.toIntOrNull()
            ?: 1
        versionName = localProps["versionName"] ?: "1.0.0"
    }

    buildTypes {
        release {
            if (localProps["key.store"] != null) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Fallback to debug signing for local dev without keystore
                signingConfig = signingConfigs.getByName("debug")
            }
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Strip native libraries for non-target architectures to reduce APK size
    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }
}

flutter {
    source = "../.."
}
