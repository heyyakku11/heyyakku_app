plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

dependencies {
  // Import the Firebase BoM
  implementation(platform("com.google.firebase:firebase-bom:34.18.0"))


  // TODO: Add the dependencies for Firebase products you want to use
  // When using the BoM, don't specify versions in Firebase dependencies
  implementation("com.google.firebase:firebase-analytics")
  
}

android {
    namespace = "com.yakku.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.yakku.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 33
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "YAKKU Dev")
            manifestPlaceholders["appLinkHost"] = "heyyakku-web-git-develop-heyyakku33-9072.vercel.app"
        }

        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            resValue("string", "app_name", "YAKKU Stage")
            manifestPlaceholders["appLinkHost"] = "heyyakku-web-git-staging-heyyakku33-9072.vercel.app"
        }

        create("production") {
            dimension = "environment"
            resValue("string", "app_name", "YAKKU")
            manifestPlaceholders["appLinkHost"] = "heyyakku.com"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

// Source of truth: ../../firebase/<flavor>/google-services.json
// Synced into android/app/src/<flavor>/ so the Google Services plugin can find them.
val firebaseRoot = rootProject.file("../firebase")
listOf("dev", "staging", "production").forEach { flavor ->
    val source = File(firebaseRoot, "$flavor/google-services.json")
    if (!source.exists()) {
        logger.warn("Missing Firebase Android config: ${source.path}")
        return@forEach
    }
    val destinationDir = file("src/$flavor")
    destinationDir.mkdirs()
    source.copyTo(File(destinationDir, "google-services.json"), overwrite = true)
}
