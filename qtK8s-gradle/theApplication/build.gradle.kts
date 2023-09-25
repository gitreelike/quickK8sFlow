import com.google.cloud.tools.jib.gradle.JibTask

plugins {
    id("io.spring.dependency-management") version "1.1.3"
    id("org.springframework.boot") version "3.1.3"
    kotlin("plugin.spring") version "1.8.22"
    id("kotlin-conventions")
    id("com.google.cloud.tools.jib")
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
    implementation("org.jetbrains.kotlin:kotlin-reflect")
    testImplementation("org.springframework.boot:spring-boot-starter-test")
}

tasks.withType<Test> {
    useJUnitPlatform()
}

tasks.withType<JibTask> {
    dependsOn(tasks.jar)
    // jibBuildTar doesn't declare its inputs correctly, and is always up-to-date as a result
    // ...facepalm (p.-)
    inputs.file(tasks.jar.get().outputs.files.singleFile)
}

afterEvaluate {
    jib {
        from { image = "docker.io/azul/zulu-openjdk:17" }
        to {
            image = "qtk8s:$version"
        }
    }
}
