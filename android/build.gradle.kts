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

// AUTO: Force all plugins to compileSdk 36
subprojects {
    val proj = this
    val configureProject = {
        val android = proj.extensions.findByName("android")
        if (android != null) {
            try {
                val method = android::class.java.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                method.invoke(android, 36)
                println("Set compileSdkVersion to 36 for project: ${proj.name}")
            } catch (e: Exception) {
                try {
                    val method = android::class.java.getMethod("setCompileSdk", java.lang.Integer::class.java)
                    method.invoke(android, 36)
                    println("Set compileSdk to 36 for project: ${proj.name}")
                } catch (e2: Exception) {
                    println("Failed to set compileSdk for project: ${proj.name}: ${e2.message}")
                }
            }
        }
    }
    if (proj.state.executed) {
        configureProject()
    } else {
        proj.afterEvaluate {
            configureProject()
        }
    }
}
