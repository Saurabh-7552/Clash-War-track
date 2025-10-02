package com.example.clashwartrackerbackend.controller;

import com.example.clashwartrackerbackend.dto.LeaderboardEntryDto;
import com.example.clashwartrackerbackend.dto.PlayerWarResultDto;
import com.example.clashwartrackerbackend.entity.PlayerWarResult;
import com.example.clashwartrackerbackend.repository.PlayerWarResultRepository;
import com.example.clashwartrackerbackend.service.ClashService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.CrossOrigin;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = {"http://localhost:5173", "http://localhost:5174", "http://localhost:3000"})
public class ClashController {

    @Autowired
    private ClashService clashService;
    
    @Autowired
    private PlayerWarResultRepository playerWarResultRepository;

    @GetMapping("/fetch-currentwar")
    public List<PlayerWarResultDto> fetchCurrentWar(@RequestParam(value = "clanTag", required = true) String clanTag) {
        try {
            System.out.println("Received clan tag: " + clanTag);
            // URL decode the clan tag if needed
            String decodedClanTag = java.net.URLDecoder.decode(clanTag, "UTF-8");
            System.out.println("Decoded clan tag: " + decodedClanTag);
            
            // Remove # if it exists since we'll add it in the service
            if (decodedClanTag.startsWith("#")) {
                decodedClanTag = decodedClanTag.substring(1);
            }
            
            return clashService.fetchCurrentWar(decodedClanTag);
        } catch (IOException e) {
            System.err.println("IOException in fetchCurrentWar: " + e.getMessage());
            e.printStackTrace();
            // Return a proper error response instead of empty list
            PlayerWarResultDto errorDto = new PlayerWarResultDto();
            errorDto.setClanName("ERROR");
            errorDto.setPlayerName("API_ERROR");
            errorDto.setWarId("ERROR");
            errorDto.setStars(-999);
            return List.of(errorDto);
        } catch (Exception e) {
            System.err.println("General exception in fetchCurrentWar: " + e.getMessage());
            e.printStackTrace();
            // Return a proper error response instead of empty list
            PlayerWarResultDto errorDto = new PlayerWarResultDto();
            errorDto.setClanName("ERROR");
            errorDto.setPlayerName("GENERAL_ERROR");
            errorDto.setWarId("ERROR");
            errorDto.setStars(-999);
            return List.of(errorDto);
        }
    }

    @GetMapping("/fetch-currentwar/{clanTag}")
    public List<PlayerWarResultDto> fetchCurrentWarByPath(@PathVariable String clanTag) {
        try {
            System.out.println("Received clan tag (path): " + clanTag);
            return clashService.fetchCurrentWar(clanTag);
        } catch (IOException e) {
            System.err.println("IOException in fetchCurrentWarByPath: " + e.getMessage());
            e.printStackTrace();
            // Return a proper error response instead of empty list
            PlayerWarResultDto errorDto = new PlayerWarResultDto();
            errorDto.setClanName("ERROR");
            errorDto.setPlayerName("API_ERROR");
            errorDto.setWarId("ERROR");
            errorDto.setStars(-999);
            return List.of(errorDto);
        } catch (Exception e) {
            System.err.println("General exception in fetchCurrentWarByPath: " + e.getMessage());
            e.printStackTrace();
            // Return a proper error response instead of empty list
            PlayerWarResultDto errorDto = new PlayerWarResultDto();
            errorDto.setClanName("ERROR");
            errorDto.setPlayerName("GENERAL_ERROR");
            errorDto.setWarId("ERROR");
            errorDto.setStars(-999);
            return List.of(errorDto);
        }
    }
    
    @GetMapping("/results")
    public List<PlayerWarResult> getAllResults() {
        return playerWarResultRepository.findAllByOrderByCreatedAtDesc();
    }
    
    @GetMapping("/leaderboard")
    public List<LeaderboardEntryDto> getLeaderboard() {
        return playerWarResultRepository.findLeaderboard();
    }
    
    @GetMapping("/clear-duplicates")
    public String clearDuplicates() {
        // This is a temporary endpoint to help debug and clear duplicate data
        // In production, you'd want proper admin controls
        return "Use database query to remove duplicates: DELETE FROM player_war_results WHERE id NOT IN (SELECT MIN(id) FROM player_war_results GROUP BY player_name, war_id)";
    }
    
    @GetMapping("/clear-all-data")
    public String clearAllData() {
        try {
            playerWarResultRepository.deleteAll();
            return "✅ All war data cleared successfully! Database is now empty.";
        } catch (Exception e) {
            return "❌ Error clearing data: " + e.getMessage();
        }
    }
}
