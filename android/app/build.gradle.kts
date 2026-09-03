plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import com.android.build.gradle.internal.api.ApkVariantOutputImpl
import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "dev.casraf.pantry"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "dev.casraf.pantry"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystoreProperties.containsKey("storeFile")) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    flavorDimensions += "form"

    productFlavors {
        create("phone") {
            dimension = "form"
            isDefault = true
        }
        // Wear OS 3 is the floor where standalone distribution, the modern
        // watch Play Store and Tiles all settled.
        create("wear") {
            dimension = "form"
            minSdk = 30
            // Whether the window keeps its own left-edge swipe-to-dismiss. A
            // horizontal pager needs it off; -PwearSwipeToDismiss=true puts it
            // back for the comparison.
            resValue(
                "bool",
                "wear_swipe_to_dismiss",
                ((project.findProperty("wearSwipeToDismiss") as String?)?.toBoolean() == true).toString(),
            )
            // Impeller is what a Wear device gets by default — API 33+, no
            // denylisted GPU — and the Skia opt-out is on its way out. The
            // switch exists so the cost of that default can be quantified
            // rather than estimated: -PwearImpeller=false.
            manifestPlaceholders["wearEnableImpeller"] =
                ((project.findProperty("wearImpeller") as String?)?.toBoolean() != false).toString()
            // Play serves the highest compatible versionCode, and a watch also
            // matches the phone APK. The offset keeps the wear build ahead so
            // the watch never resolves to the phone binary. Mirrors
            // MACOS_BUILD_NUMBER in the Makefile.
            versionCode = flutter.versionCode + 20000
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-dev"
        }
        release {
            signingConfig = if (signingConfigs.names.contains("release"))
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}

val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)
android.applicationVariants.configureEach {
    val variant = this
    variant.outputs.forEach { output ->
        val abiVersionCode = abiCodes[output.filters.find { it.filterType == "ABI" }?.identifier]
        if (abiVersionCode != null) {
            (output as ApkVariantOutputImpl).versionCodeOverride = variant.versionCode * 10 + abiVersionCode
        }
    }
}

// Every flavor carries every plugin, because Flutter regenerates one
// GeneratedPluginRegistrant naming all of them. The Java classes have to stay so
// that registrant compiles, but the native libraries behind the plugins a watch
// cannot use do not have to be packaged. A plugin that opens its library at
// registration time rather than on first use would crash on startup here; the
// ones excluded below all load lazily.
//
// Set -PwearKeepNative=true to package them anyway, for a size comparison.
//
// `libflutter_avif.so` is deliberately not among them. Android's platform
// decoder handles AVIF from API 31, but that guarantee follows the handheld CDD
// and Wear OS takes the exemption: this watch ships no AV1 decoder at all, so
// neither the engine's fallback nor a direct ImageDecoder call can read an AVIF.
// The plugin is the only thing that can, and it is also the one plugin here that
// opens its library at registration rather than on first use — excluding it
// would log a load failure on every launch.
val wearStripNative = (project.findProperty("wearKeepNative") as String?)?.toBoolean() != true

val wearExcludedLibs = if (!wearStripNative) emptyList() else listOf(
    // ML Kit barcode scanning and CameraX — no camera on a watch.
    "**/libbarhopper_v3.so",
    "**/libimage_processing_util_jni.so",
    "**/libsurface_util_jni.so",
)

// The barcode models ship as assets rather than jniLibs, so the packaging DSL
// does not reach them; they are deleted from the merged asset dir instead. The
// flutter_avif wasm is dead on the phone too — a web-only artifact the Android
// build has no reason to carry.
val wearExcludedAssets = listOf(
    "mlkit_barcode_models",
    "flutter_assets/packages/flutter_avif_web",
)

androidComponents {
    onVariants(selector().withFlavor("form" to "wear")) { variant ->
        variant.packaging.jniLibs.excludes.addAll(wearExcludedLibs)

        // Flutter's own copy task writes into the same merged directory *after*
        // AGP's merge, so the flutter_assets entries only stay deleted if the
        // sweep also runs on the later task.
        val variantName = variant.name.replaceFirstChar { it.uppercase() }
        val assetTasks = setOf("merge${variantName}Assets", "copyFlutterAssets$variantName")
        tasks.matching { it.name in assetTasks }.configureEach {
            val roots = outputs.files
            doLast {
                roots.forEach { root ->
                    wearExcludedAssets.forEach { root.resolve(it).deleteRecursively() }
                }
            }
        }
    }
}

// Disable AGP baseline profile compilation so assets/dexopt/baseline.prof(m)
// are not produced. The merged .profm is non-deterministic across build hosts,
// which breaks F-Droid reproducible builds. Remove once AGP fixes
// https://issuetracker.google.com/issues/231837768.
tasks.withType<com.android.build.gradle.internal.tasks.CompileArtProfileTask>().configureEach {
    enabled = false
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.core:core-ktx:1.13.1")
    // Both flavors: the Data Layer is two-sided and the phone is the half that
    // sends the credential. Proprietary, so tool/fdroid/apply.sh strips this
    // line and swaps DataLayerChannel.kt for a stub that reports unavailable.
    implementation("com.google.android.gms:play-services-wearable:20.0.1")
    // RemoteActivityHelper, for opening a link on the paired phone. Named as a
    // string because flavor configurations have no generated Kotlin accessor.
    add("wearImplementation", "androidx.wear:wear-remote-interactions:1.1.0")
}
