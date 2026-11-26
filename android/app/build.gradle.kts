import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.khaanabuddy"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.khaanabuddy"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            // ✅ Release signing via android/key.properties (gitignored).
            //    storeFile/khaanabuddy-release.keystore lives in android/.
            val props = Properties()
            val propFile = rootProject.file("key.properties")
            if (propFile.exists()) propFile.inputStream().use { props.load(it) }
            storeFile = rootProject.file(props.getProperty("storeFile", "khaanabuddy-release.keystore"))
            storePassword = props.getProperty("storePassword", "")
            keyAlias = props.getProperty("keyAlias", "khaanabuddy")
            keyPassword = props.getProperty("keyPassword", "")
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
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
