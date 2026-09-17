plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Helper to read local.properties values (for local dev)
fun prop(key: String): String? {
    val f = rootProject.file("local.properties")
    if (f.exists()) {
        val p = java.util.Properties()
        f.inputStream().use { p.load(it) }
        return p[key] as? String
    }
    return null
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

    signingConfigs {
        create("release") {
            val storeFile = prop("key.store")
            if (storeFile != null) {
                this.storeFile = file(storeFile)
                this.storePassword = prop("key.store.password") ?: ""
                this.keyAlias = prop("key.alias") ?: ""
                this.keyPassword = prop("key.key.password") ?: ""
            }
        }
    }

    defaultConfig {
        applicationId = "com.haffar.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = (System.getenv("VERSION_CODE") ?: prop("versionCode") ?: "1").toInt()
        versionName = System.getenv("VERSION_NAME") ?: prop("versionName") ?: "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = if (signingConfigs["release"].storeFile != null) {
                signingConfigs["release"]
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
