import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Assinatura de release.
//
// O ficheiro android/key.properties nunca entra no Git (ver android/.gitignore)
// e aponta para a keystore, que também fica fora do repositório. Enquanto não
// existir, o build de release cai na chave de debug para continuar a funcionar
// em `flutter run --release`.
//
// Formato esperado:
//   storePassword=...
//   keyPassword=...
//   keyAlias=lume
//   storeFile=C:/caminho/absoluto/para/lume-release.jks
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (hasReleaseKeystore) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

android {
    namespace = "com.lume.launcher"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Definido na FASE 0 do plano.
        applicationId = "com.lume.launcher"
        // Android 7.0. É o mínimo suportado pelo Flutter 3.44; descer mais
        // não é possível sem sair do canal estável.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resourceConfigurations += listOf("en", "pt")
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Aviso propositado: um APK assim NÃO é distribuível.
                logger.warn(
                    "[Lume] android/key.properties não existe — o release vai " +
                        "ser assinado com a chave de debug e não serve para " +
                        "distribuição.",
                )
                signingConfigs.getByName("debug")
            }
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
