allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")

    // Force any Flutter plugin subproject (e.g. receive_sharing_intent)
    // that defaults to a different Kotlin jvmTarget to match this app's
    // Java/Kotlin compatibility, avoiding "Inconsistent JVM Target
    // Compatibility Between Java and Kotlin Tasks" build failures.
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }

    // flutter_avif_android 3.1.0 ships the same FlutterAvifPlugin class as both
    // a .kt and a .java in the same package; with this project's Kotlin/AGP the
    // Java copy is fed into both compilers and collides ("Redeclaration").
    // AGP wires it through KotlinCompile.javaSources and the AGP java source set
    // as raw dirs, so ordinary source-set/task excludes are ignored — filter
    // those two file collections directly. The Kotlin copy is kept.
    if (project.name == "flutter_avif_android") {
        project.afterEvaluate {
            fun dropDuplicate(fc: org.gradle.api.file.ConfigurableFileCollection) {
                val snapshot = project.files(fc.files.toList())
                fc.setFrom(snapshot.asFileTree.matching { exclude("**/FlutterAvifPlugin.java") })
            }
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                val getJavaSources = javaClass.methods.firstOrNull {
                    it.name == "getJavaSources" && it.parameterCount == 0
                } ?: return@configureEach
                (getJavaSources.invoke(this) as? org.gradle.api.file.ConfigurableFileCollection)
                    ?.let(::dropDuplicate)
            }
            tasks.withType<JavaCompile>().configureEach {
                exclude("**/FlutterAvifPlugin.java")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
