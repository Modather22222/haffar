plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Read keystore from gradle.properties or CI env vars
val storeFile = project.findProperty("key.store") as? String
    ?: System.getenv("KEYSTORE_PATH")
val storePassword = project.findProperty("key.store.password") as? String
    ?: System.getenv("KEYSTORE_PASSWORD") ?: ""
val keyAlias = project.findProperty("key.alias") as? String
    ?: System.getenv("KEY_ALIAS") ?: ""
val keyPassword = project.findProperty("key.key.password") as? String
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
            if (storeFile != null) {
                this.storeFile = file(storeFile)
                this.storePassword = storePassword
                this.keyAlias = keyAlias
                this.keyPassword = keyPassword
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
            signingConfig = if (storeFile != null) {
                signingConfigs.getByName("release")
            } else {
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
