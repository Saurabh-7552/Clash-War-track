package com.example.clashwartrackerbackend.repository;

import com.example.clashwartrackerbackend.dto.LeaderboardEntryDto;
import com.example.clashwartrackerbackend.entity.PlayerWarResult;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PlayerWarResultRepository extends JpaRepository<PlayerWarResult, Long> {
    
    List<PlayerWarResult> findByWarId(String warId);
    
    List<PlayerWarResult> findByPlayerName(String playerName);
    
    List<PlayerWarResult> findAllByOrderByCreatedAtDesc();
    
    @Query("SELECT new com.example.clashwartrackerbackend.dto.LeaderboardEntryDto(r.clanName, r.playerName, SUM(r.stars)) FROM PlayerWarResult r GROUP BY r.clanName, r.playerName ORDER BY SUM(r.stars) DESC")
    List<LeaderboardEntryDto> findLeaderboard();
}
