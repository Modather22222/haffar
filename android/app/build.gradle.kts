import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Signing sources, highest priority first:
//   1. android/key.properties  (local, gitignored — Flutter reference pattern)
//   2. gradle.properties / -P  (key.store, key.store.password, …)
//   3. CI env vars             (KEYSTORE_PATH, KEYSTORE_PASSWORD, …)
// `file()` resolves against android/app/, rootProject.file() against android/.
val keyProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
fun prop(name: String): String? =
    keyProps.getProperty(name) ?: project.findProperty(name) as? String

val keystoreRaw = prop("storeFile")
    ?: prop("key.store")
    ?: System.getenv("KEYSTORE_PATH")
val keystoreFile = keystoreRaw
    ?.let { listOf(file(it), rootProject.file(it)) }
    ?.firstOrNull { it.exists() }
val ksStorePassword = prop("storePassword")
    ?: prop("key.store.password")
    ?: System.getenv("KEYSTORE_PASSWORD")
    ?: ""
val ksKeyAlias = prop("keyAlias")
    ?: prop("key.alias")
    ?: System.getenv("KEY_ALIAS")
    ?: ""
val ksKeyPassword = prop("keyPassword")
    ?: prop("key.key.password")
    ?: System.getenv("KEY_PASSWORD")
    ?: ""

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
        // Create only when a keystore is actually present so debug builds
        // never fail at configuration time (the old code threw here and
        // broke `flutter run` whenever KEYSTORE_PATH was unset).
        if (keystoreFile != null) {
            create("release") {
                storeFile = keystoreFile
                storePassword = ksStorePassword
                keyAlias = ksKeyAlias
                keyPassword = ksKeyPassword
            }
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
            // Fail fast only when a release build is actually requested.
            signingConfig = signingConfigs.findByName("release")
                ?: throw GradleException(
                    "Release signing requires a keystore. Put it at " +
                        "android/key/release.keystore and set android/key.properties " +
                        "(storeFile/storePassword/keyAlias/keyPassword), or set " +
                        "KEYSTORE_PATH (CI)."
                )
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
