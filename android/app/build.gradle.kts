import java.io.FileInputStream
import java.io.InputStreamReader
import java.time.ZonedDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Properties
import com.android.build.gradle.internal.api.BaseVariantOutputImpl

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0.0"

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
}

// ─── 修正點 1：最外層計算時間字串（GMT+8） ───
val formattedTimeInfo = ZonedDateTime.now(ZoneId.of("GMT+8"))
    .format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))

android {
    namespace = "com.huaweidigi.tutoring"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    // 直接設定 base name，AGP 產生的 bundle 前綴會套用此名稱
    setProperty("archivesBaseName", "補習班_${flutterVersionName}_${formattedTimeInfo}")

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.huaweidigi.tutoring"
        minSdk = 24
        targetSdk = 36
        versionCode = 4
        versionName = "1.0.0"

        // 指定 ABI 架構
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }

        // ─── 2. 決定 AAB 的預設前綴檔名 ───
        project.extra["archivesBaseName"] = "補習班_${versionName}_${formattedTimeInfo}"
    }

    // ─── 3. 精準複寫 APK 的檔名 ───
    applicationVariants.all {
        if (buildType.name == "release") {
            val name = "補習班"
            val version = versionName
            outputs.all {
                (this as? BaseVariantOutputImpl)?.outputFileName = "${name}_${version}_${formattedTimeInfo}.apk"
            }
        }
    }

    buildTypes {
        release {
            // 修正：直接指定 release 簽署配置
            signingConfig = signingConfigs.getByName("release")
            isShrinkResources = false
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}