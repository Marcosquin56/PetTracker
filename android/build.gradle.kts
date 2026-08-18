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
}

// Algunos plugins (file_picker, vía flutter_plugin_android_lifecycle) exigen
// compileSdk 36+, más nuevo que el default que trae esta versión de Flutter.
// Se fuerza acá para todos los subproyectos (los plugins también son
// subproyectos Gradle) en vez de esperar a actualizar el Flutter SDK entero.
subprojects {
    val applyCompileSdk = {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.compileSdkVersion(36)
        Unit
    }
    // `evaluationDependsOn(":app")` de arriba ya deja algunos subproyectos
    // evaluados para cuando llegamos acá — afterEvaluate() explota si se
    // registra sobre un proyecto que ya terminó de evaluarse.
    if (state.executed) applyCompileSdk() else afterEvaluate { applyCompileSdk() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
