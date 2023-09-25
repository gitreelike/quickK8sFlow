package de.akquinet.cc.zusi.qtk8sgradle

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("hello")
class HelloWorldController {

    @GetMapping
    fun hello(): String = "Hello :)"
}