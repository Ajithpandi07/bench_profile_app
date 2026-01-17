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
    val forceCompileSdk: (Project) -> Unit = { p ->
        p.extensions.findByName("android")?.apply {
            try {
                val setCompileSdkVersion = this.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                setCompileSdkVersion.invoke(this, 36)
            } catch (e: Exception) {
               // ignore
            }
        }
    }

    if (project.state.executed) {
        forceCompileSdk(project)
    } else {
        afterEvaluate {
            forceCompileSdk(project)
        }
    }

    if (name == "isar_flutter_libs") {
        if (project.state.executed) {
            extensions.findByName("android")?.apply {
                 try {
                    val setNamespace = this::class.java.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(this, "dev.isar.isar_flutter_libs")
                } catch (e: Exception) {
                    println("Issue setting namespace for isar_flutter_libs: ${e.message}")
                }
            }
        } else {
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
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
