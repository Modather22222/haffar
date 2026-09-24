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
    namespace = "com.appy.haffar"
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
                ?: throw GradleException(
                    "Release signing requires a keystore. Set key.store in " +
                    "gradle.properties or KEYSTORE_PATH (CI)."
                )
            storeFile = ks
            storePassword = ksStorePassword
            keyAlias = ksKeyAlias
            keyPassword = ksKeyPassword
        }
    }

    defaultConfig {
        applicationId = "com.appy.haffar"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = (System.getenv("VERSION_CODE") ?: "1").toInt()
        versionName = System.getenv("VERSION_NAME") ?: "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // R8 shrink + obfuscate for smaller, harder-to-reverse APKs.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
