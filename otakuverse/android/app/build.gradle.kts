plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.mevcode.otakuverse"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ Plus besoin du desugaring
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.mevcode.otakuverse"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Firebase BoM — gère toutes les versions automatiquement
    implementation(platform("com.google.firebase:firebase-bom:34.11.0"))

    // ✅ Push notifications — obligatoire
    implementation("com.google.firebase:firebase-messaging")

    // ✅ Analytics — optionnel, à garder si tu veux les stats Firebase
    implementation("com.google.firebase:firebase-analytics")
}
