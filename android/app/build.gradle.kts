import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (!keystorePropertiesFile.exists()) {
    throw GradleException(
        "Arquivo android/key.properties não encontrado. Configure a assinatura release antes de gerar o bundle.",
    )
}

keystoreProperties.load(FileInputStream(keystorePropertiesFile))

fun requiredKeystoreProperty(name: String): String {
    return keystoreProperties.getProperty(name)?.trim()?.takeIf { it.isNotEmpty() }
        ?: throw GradleException(
            "Chave obrigatória ausente em android/key.properties: $name",
        )
}

val releaseStoreFilePath = requiredKeystoreProperty("storeFile")
val releaseStoreFile = file(releaseStoreFilePath)

if (!releaseStoreFile.exists()) {
    throw GradleException(
        "O arquivo do keystore configurado em android/key.properties não foi encontrado: $releaseStoreFilePath",
    )
}

android {
    namespace = "app.luminadigital.zeni"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        create("release") {
            keyAlias = requiredKeystoreProperty("keyAlias")
            keyPassword = requiredKeystoreProperty("keyPassword")
            storeFile = releaseStoreFile
            storePassword = requiredKeystoreProperty("storePassword")
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "app.luminadigital.zeni"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
