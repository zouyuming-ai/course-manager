plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.zouyuming.coursemanager"
    compileSdk = 35

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.zouyuming.coursemanager"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file("../keystore/release-key.jks")
            storePassword = "course_manager_2026"
            keyAlias = "release"
            keyPassword = "course_manager_2026"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    lint {
        abortOnError = false
        checkReleaseBuilds = false
        quiet = true
    }

    tasks.whenTaskAdded {
        if (name.startsWith("lint")) {
            enabled = false
        }
    }

    packaging {
        resources {
            pickFirst("META-INF/kotlinx_coroutines_core.version")
            pickFirst("META-INF/androidx/annotation/annotation/LICENSE.txt")
            pickFirst("META-INF/LICENSE*")
            pickFirst("META-INF/NOTICE*")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.core:core:1.15.0")
}
