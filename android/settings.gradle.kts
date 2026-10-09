// Fix for AGP AndroidLocationsException when both ANDROID_PREFS_ROOT and ANDROID_USER_HOME are set in environment
try {
    val peClass = Class.forName("java.lang.ProcessEnvironment")
    peClass.declaredFields.forEach { field ->
        try {
            field.isAccessible = true
            val obj = field.get(null)
            if (obj is MutableMap<*, *>) {
                obj.keys.removeIf { k -> k.toString().equals("ANDROID_PREFS_ROOT", ignoreCase = true) }
            }
        } catch (_: Throwable) {}
    }
} catch (e: Throwable) {
    println("Notice: Could not modify environment map: $e")
}

pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
