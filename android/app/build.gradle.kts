plugins {
    id("com.android.application")

    id("com.google.gms.google-services")
    id("kotlin-android")
>>>>>>> 04c21b4 (Initial commit: KhaanaBuddy Flutter app)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.khaanabuddy"

    ndkVersion = "27.0.12077973"
    compileSdk = 35  // Update to 34
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17  // Update to 17
        targetCompatibility = JavaVersion.VERSION_17  // Update to 17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()  // Update to 17
    }

    defaultConfig {
        applicationId = "com.example.khaanabuddy"
        minSdk = 21  // Set explicit version
        targetSdk = 35  // Update to 34
        versionCode = 1
        versionName = "1.0.0"
>>>>>>> 04c21b4 (Initial commit: KhaanaBuddy Flutter app)
    }

    buildTypes {
        release {

            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
>>>>>>> 04c21b4 (Initial commit: KhaanaBuddy Flutter app)
        }
    }
}

flutter {
    source = "../.."

}
>>>>>>> 04c21b4 (Initial commit: KhaanaBuddy Flutter app)
