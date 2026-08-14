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
// Algunos plugins traen su propio modulo Android con un compileSdk antiguo
// hardcodeado (flutter_native_splash 2.4.4 usa 31). Las dependencias AndroidX
// modernas exigen compilar contra API 34+, asi que el build falla en
// checkDebugAarMetadata. Aqui se eleva el compileSdk de cualquier submodulo que
// se haya quedado corto.
//
// Debe ir ANTES del bloque evaluationDependsOn(":app") de abajo: esa llamada
// evalua :app de inmediato y despues ya no se le pueden registrar callbacks.
subprojects {
    afterEvaluate {
        extensions
            .findByType(com.android.build.api.dsl.LibraryExtension::class.java)
            ?.let { android ->
                if ((android.compileSdk ?: 0) < 36) {
                    android.compileSdk = 36
                }
            }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
