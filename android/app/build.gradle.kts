plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.coremind"
    compileSdk = 36  // ✅ Updated to match Gallery
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.coremind"
        minSdk = 31  // ✅ Updated to match Gallery (minimum for stable GenAI)
        targetSdk = 35  // ✅ Updated to match Gallery
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ EXACT SAME MEDIAPIPE VERSIONS AS GOOGLE AI EDGE GALLERY
    implementation("com.google.mediapipe:tasks-genai:0.10.24")  // Latest GenAI version
    implementation("com.google.mediapipe:tasks-text:0.10.14")   // Text processing support

    // ✅ TENSORFLOW LITE DEPENDENCIES (Gallery uses these for model support)
    implementation("org.tensorflow:tensorflow-lite:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-gpu:2.14.0")  // GPU acceleration
    implementation("org.tensorflow:tensorflow-lite-support:0.4.4")

    // ✅ COROUTINES (you already have this - good!)
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")

    // ✅ PROTOBUF SUPPORT (Gallery uses this for model data)
    implementation("com.google.protobuf:protobuf-javalite:3.25.1")

    // ✅ ANDROIDX LIFECYCLE (you already have this - good!)
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")

    // ✅ WORK MANAGER (Gallery uses this for background downloads)
    implementation("androidx.work:work-runtime-ktx:2.9.0")

    // ✅ ANDROIDX CORE (likely already included by Flutter, but explicit is better)
    implementation("androidx.core:core-ktx:1.12.0")
}
