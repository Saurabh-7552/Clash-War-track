package com.example.clashwartrackerbackend.controller;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = {"http://localhost:5173", "http://localhost:5174", "http://localhost:3000"})
public class HelloController {

    @GetMapping("/hello")
    public String hello() {
        return "Hello World";
    }
    
    @GetMapping("/health")
    public String health() {
        return "Backend is running!";
    }
}
