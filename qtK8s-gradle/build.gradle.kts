import com.google.cloud.tools.jib.gradle.BuildTarTask
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

group = "de.akquinet.cc.zusi"

version = "0.0.1-SNAPSHOT"

plugins { id("kotlin-conventions") }

tasks.withType<KotlinCompile> {
  kotlinOptions {
    freeCompilerArgs += "-Xjsr305=strict"
    jvmTarget = "17"
  }
}

allprojects { repositories { mavenCentral() } }

subprojects {
  group = parent!!.group
  version = parent!!.version
}

val minikubeEnsureRunning by
    tasks.registering {
      doLast {
        val res = exec {
          isIgnoreExitValue = true
          commandLine = listOf("src/main/shell/minikube-ensure-running.sh")
          errorOutput = System.out
        }
        didWork =
            when (res.exitValue) {
              0 -> false
              100 -> true
              else ->
                  throw TaskExecutionException(
                      this,
                      org.gradle.process.internal.ExecException(
                          "$name: execution failed, exit code ${res.exitValue}"))
            }
      }
    }

val minikubeEnsureImages by
    tasks.registering {
      val jibTasks = subprojects.mapNotNull { it.tasks.findByName("jibBuildTar") as BuildTarTask? }
      dependsOn(minikubeEnsureRunning, *jibTasks.toTypedArray())
      outputs.upToDateWhen { false }
      doLast {
        val res = exec {
          isIgnoreExitValue = true
          commandLine =
              listOf(
                  "src/main/shell/minikube-ensure-images.sh",
                  *jibTasks.flatMap { listOf(it.jib!!.to.image, it.outputFile) }.toTypedArray())
          errorOutput = System.out
        }
        didWork =
            when (res.exitValue) {
              0 -> false
              100 -> true
              else ->
                  throw TaskExecutionException(
                      this,
                      org.gradle.process.internal.ExecException(
                          "$name: execution failed, exit code ${res.exitValue}"))
            }
      }
    }

val minikubeDeploy by
    tasks.registering(Exec::class) {
      dependsOn(minikubeEnsureRunning, minikubeEnsureImages)
      group = "qtK8sShowcase Tasks"
      description =
          "Starts a minikube in profile \"qtK8sShowcase\" (if not already running) and deploys locally build images."
      commandLine = listOf("src/main/shell/local-deploy.sh")
      errorOutput = System.out
      val failFile = layout.buildDirectory.file("minikubeDeploy.failed")
      outputs.upToDateWhen {
        val forceDeploy: String? by rootProject.extra
        !failFile.get().asFile.exists() &&
            taskDependencies.getDependencies(it).none { dep -> dep.didWork } &&
            forceDeploy == null
      }

      inputs.dir("src/main/shell")
      inputs.dir("../k8s-conf")
      outputs.file(failFile)
      doFirst { failFile.get().asFile.createNewFile() }
      doLast {
        this as Exec
        if (executionResult.get().exitValue == 0) {
          failFile.get().asFile.delete()
        }
      }
    }
