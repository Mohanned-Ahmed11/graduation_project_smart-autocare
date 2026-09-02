import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

/**
 * Resolves the Maps SDK key for AndroidManifest. Order: env vars → local.properties →
 * repo [.env] GOOGLE_MAPS_API_KEY or MAPS_API_KEY → Gradle MAPS_API_KEY property.
 * Matches [Env.googleMapsApiKey] in Flutter so a filled .env maps to native tiles.
 */
fun readMapsApiKey(androidProjectDir: File): String {
    fun String?.nonEmpty(): String? = this?.trim()?.takeIf { it.isNotEmpty() }

    System.getenv("GOOGLE_MAPS_API_KEY").nonEmpty()?.let { return it }
    System.getenv("MAPS_API_KEY").nonEmpty()?.let { return it }

    val localFile = File(androidProjectDir, "local.properties")
    if (localFile.exists()) {
        val p = Properties()
        localFile.inputStream().use { p.load(it) }
        p.getProperty("GOOGLE_MAPS_API_KEY").nonEmpty()?.let { return it }
        p.getProperty("MAPS_API_KEY").nonEmpty()?.let { return it }
    }

    val envFile = File(androidProjectDir.parentFile, ".env")
    if (envFile.exists()) {
        envFile.readLines().forEach { raw ->
            val line = raw.trim()
            if (line.isEmpty() || line.startsWith("#")) return@forEach
            val eq = line.indexOf('=')
            if (eq <= 0) return@forEach
            val key = line.substring(0, eq).trim()
            if (key != "GOOGLE_MAPS_API_KEY" && key != "MAPS_API_KEY") return@forEach
            var value = line.substring(eq + 1).trim()
            if (value.length >= 2) {
                val q0 = value.first()
                val q1 = value.last()
                if ((q0 == '"' && q1 == '"') || (q0 == '\'' && q1 == '\'')) {
                    value = value.substring(1, value.length - 1).trim()
                }
            }
            if (value.isNotEmpty()) return value
        }
    }
    return ""
}

android {
    namespace = "com.smartautocar.smart_auto_car"
    compileSdk = flutter.compileSdkVersion
    // Keep Android NDK aligned with plugin requirements.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.smartautocar.smart_auto_car"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        val mapsKey = sequenceOf(
            readMapsApiKey(rootProject.projectDir),
            (project.findProperty("MAPS_API_KEY") as? String)?.trim().orEmpty(),
        ).firstOrNull { it.isNotEmpty() } ?: ""
        manifestPlaceholders["MAPS_API_KEY"] = mapsKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
