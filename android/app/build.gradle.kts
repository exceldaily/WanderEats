import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") apply false
    id("com.google.firebase.crashlytics") apply false
}

// google-services.json (gitignored, from the Firebase console) is optional:
// a fresh clone without it still builds, just without Firebase wired in.
// Crashlytics plugin must be applied alongside it, or FirebaseInitProvider
// crashes at launch looking for a build ID that plugin generates.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

// Google Maps key comes from android/local.properties (MAPS_API_KEY=...),
// which is gitignored. Missing key -> empty placeholder, app still builds.
val localProperties = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val mapsApiKey: String = localProperties.getProperty("MAPS_API_KEY") ?: ""

// Release signing from android/key.properties (gitignored). Absent file ->
// release falls back to debug signing so CI/fresh clones still build.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.wanderbites.wanderbites"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.wanderbites.app"
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Debug fallback keeps fresh clones building, but a debug-signed
            // release AAB fails only at Play upload with a cryptic
            // fingerprint error, so make the fallback loud.
            if (!hasReleaseKeystore) {
                logger.warn(
                    "WARNING: key.properties not found - RELEASE build will be " +
                        "DEBUG-SIGNED and Play will reject it."
                )
            }
            signingConfig = if (hasReleaseKeystore)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")

            // R8: smaller download, obfuscated symbols. Keep rules for
            // RevenueCat/Billing live in proguard-rules.pro; revisit that
            // file whenever a release-only crash smells like reflection.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
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
