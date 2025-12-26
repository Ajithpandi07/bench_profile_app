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

subprojects {
    if (name == "isar_flutter_libs") {
        afterEvaluate {
            extensions.findByName("android")?.apply {
                try {
                    val setNamespace = this::class.java.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(this, "dev.isar.isar_flutter_libs")
                } catch (e: Exception) {
                    println("Issue setting namespace for isar_flutter_libs: ${e.message}")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
