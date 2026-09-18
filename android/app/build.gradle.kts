plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Read keystore from gradle.properties or CI env vars.
// NOTE: `file()` resolves against android/app/, rootProject.file() against
// android/ — so try both bases and only use the keystore if it really exists.
// CI passes an absolute path via KEYSTORE_PATH, which matches either way.
val keystoreRaw = (project.findProperty("key.store") as? String)
    ?: System.getenv("KEYSTORE_PATH")
val keystoreFile = keystoreRaw
    ?.let { listOf(file(it), rootProject.file(it)) }
    ?.firstOrNull { it.exists() }
val ksStorePassword = (project.findProperty("key.store.password") as? String)
    ?: System.getenv("KEYSTORE_PASSWORD") ?: ""
val ksKeyAlias = (project.findProperty("key.alias") as? String)
    ?: System.getenv("KEY_ALIAS") ?: ""
val ksKeyPassword = (project.findProperty("key.key.password") as? String)
    ?: System.getenv("KEY_PASSWORD") ?: ""

android {
    namespace = "com.haffar.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("release") {
            val ks = keystoreFile
            if (ks != null) {
                storeFile = ks
                storePassword = ksStorePassword
                keyAlias = ksKeyAlias
                keyPassword = ksKeyPassword
            }
        }
    }

    defaultConfig {
        applicationId = "com.haffar.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = (System.getenv("VERSION_CODE") ?: "1").toInt()
        versionName = System.getenv("VERSION_NAME") ?: "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = if (keystoreFile != null) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("No keystore file found — signing release build with debug keys.")
                signingConfigs.getByName("debug")
            }
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
