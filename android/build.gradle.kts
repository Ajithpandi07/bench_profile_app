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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

gradle.projectsEvaluated {
    subprojects.forEach { proj ->
        try {
            val androidExt = proj.extensions.findByName("android")
            if (androidExt != null) {
                // Try to obtain current namespace via reflection
                val currentNs: String? = try {
                    val getter = androidExt.javaClass.methods.firstOrNull { it.name == "getNamespace" && it.parameterCount == 0 }
                    getter?.invoke(androidExt) as? String
                } catch (_: Exception) {
                    null
                }

                if (currentNs.isNullOrBlank()) {
                    val fallback = "dev.isar.${proj.name}"
                    try {
                        val setter = androidExt.javaClass.methods.firstOrNull { it.name == "setNamespace" && it.parameterCount == 1 }
                        if (setter != null) {
                            setter.invoke(androidExt, fallback)
                        } else {
                            // last resort: reflectively set a 'namespace' field if present
                            try {
                                val field = androidExt.javaClass.getDeclaredField("namespace")
                                field.isAccessible = true
                                field.set(androidExt, fallback)
                            } catch (e: NoSuchFieldException) {
                                // ignore: not all android extension implementations expose a field
                                println("Notice: couldn't set namespace reflectively for ${proj.path}")
                            }
                        }
                        println("Setting fallback namespace for project ${proj.path} -> $fallback")
                    } catch (e: Exception) {
                        println("Warning: failed to set namespace for ${proj.path}: ${e.message}")
                    }
                }
            }
        } catch (err: Exception) {
            println("Warning: namespace fallback snippet error for project ${proj.path}: ${err.message}")
        }
    }
}
