plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.yusuf.yasin_tahlil"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        create("release") {
            // JKS kamu sudah terenkripsi dengan password ini
            keyAlias = "ILOVEYOU"
            keyPassword = "159753" 
            storeFile = file("ILOVEYOU.jks")
            storePassword = "159753"
            
            // Mengarahkan agar menggunakan format enkripsi PKCS12 yang lebih aman
            enableV1Signing = true
            enableV2Signing = true
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    // Membungkam warning Java 8 agar terminal bersih
    tasks.withType<JavaCompile> {
        options.compilerArgs.add("-Xlint:-options")
    }

    defaultConfig {
        applicationId = "com.yusuf.yasin_tahlil"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            
            // --- AKTIVASI PROGUARD (ENKRIPSI/ACAK KODE) ---
            isMinifyEnabled = true      // Mengacak nama fungsi agar tidak bisa dibaca pembajak
            isShrinkResources = true    // Menghapus file sampah agar APK lebih ringan
            
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}