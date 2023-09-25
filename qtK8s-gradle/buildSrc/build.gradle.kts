
plugins {
  `kotlin-dsl`
  `java-gradle-plugin`
}

val kotlinVersion: String by rootProject.extra

dependencies {
  implementation("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
  implementation("org.jetbrains.kotlinx:kotlinx-benchmark-plugin:0.4.8")
  implementation("com.google.cloud.tools:jib-gradle-plugin:3.3.2")
  implementation("com.google.cloud.tools:jib-spring-boot-extension-gradle:0.1.0")
}

repositories {
  mavenCentral()
  gradlePluginPortal()
}