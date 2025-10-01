package com.example.clashwartrackerbackend.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "player_war_results")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PlayerWarResult {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "player_name", nullable = false)
    private String playerName;
    
    @Column(name = "war_id", nullable = false)
    private String warId;
    
    @Column(name = "stars", nullable = false)
    private Integer stars;
    
    @Column(name = "created_at")
    private java.time.LocalDateTime createdAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = java.time.LocalDateTime.now();
    }
}
