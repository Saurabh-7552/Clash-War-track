package com.example.clashwartrackerbackend.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.transaction.annotation.EnableTransactionManagement;

@Configuration
@EnableJpaRepositories(basePackages = "com.example.clashwartrackerbackend.repository")
@EnableTransactionManagement
@ConditionalOnProperty(name = "spring.datasource.url")
public class DatabaseConfig {
    // Database configuration class
}
