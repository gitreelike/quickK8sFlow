package de.akquinet.zusi.qtk8smaven.systemtest

import io.restassured.RestAssured.get
import org.hamcrest.core.StringEndsWith
import org.hamcrest.core.StringStartsWith
import org.junit.jupiter.api.Test

class HelloST {

  @Test
  fun `can say hello`() {
        get("http://localhost:30080/hello")
            .then()
            .statusCode(200)
            .body(StringStartsWith("Hello"))
  }

  @Test
  fun `should be friendly`() {
        get("http://localhost:30080/hello")
            .then()
            .statusCode(200)
            .body(StringEndsWith(":)"))
  }

}
