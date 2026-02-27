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
            // Konfigurasi JKS Yusuf Ardiansyah
            keyAlias = "ILOVEYOU"
            keyPassword = "159753" 
            storeFile = file("ILOVEYOU.jks")
            storePassword = "159753"
            
            enableV1Signing = true
            enableV2Signing = true
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        // Diperbarui ke Java 11 untuk menghilangkan warning obsolete
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        // Diperbarui ke Java 11 agar sinkron dengan compileOptions
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Membungkam warning Java jika masih muncul di compiler
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
            
            // --- AKTIVASI PROGUARD (KEAMANAN APLIKASI) ---
            isMinifyEnabled = true      
            isShrinkResources = true    
            
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
    // Dukungan fitur Java modern untuk Android lama
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}