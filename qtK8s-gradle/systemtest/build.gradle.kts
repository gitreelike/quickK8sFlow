
plugins {
    id("io.spring.dependency-management") version "1.1.3"
    id("org.springframework.boot") version "3.1.3"
    id("kotlin-conventions")
}


dependencies {
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("io.rest-assured:rest-assured")
}

tasks.bootJar { enabled = false }

tasks.test {
    doFirst {
        throw StopExecutionException(
            ":systemtest:test doesn't do anything, use systemtest to run the system tests!"
        )
    }
}

tasks.register<Test>("systemtest") {
    dependsOn(project.rootProject.tasks.getByPath("minikubeDeploy"))
    description = "Runs the system tests."
    group = "verification"

    val test by sourceSets.getting

    testClassesDirs = test.output.classesDirs
    classpath = test.runtimeClasspath
    
    useJUnitPlatform()
    include("**/*ST.class")

    // depends on external resources, so can never be up to date
    outputs.upToDateWhen { false }
}