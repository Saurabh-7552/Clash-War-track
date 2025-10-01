package com.example.clashwartrackerbackend.controller;

import com.example.clashwartrackerbackend.dto.LeaderboardEntryDto;
import com.example.clashwartrackerbackend.dto.PlayerWarResultDto;
import com.example.clashwartrackerbackend.entity.PlayerWarResult;
import com.example.clashwartrackerbackend.repository.PlayerWarResultRepository;
import com.example.clashwartrackerbackend.service.ClashService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

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
            System.err.println("Error details: " + e.getMessage());
            return List.of(); // Return empty list on error
        } catch (Exception e) {
            System.err.println("General error: " + e.getMessage());
            return List.of(); // Return empty list on error
        }
    }

    @GetMapping("/fetch-currentwar/{clanTag}")
    public List<PlayerWarResultDto> fetchCurrentWarByPath(@PathVariable String clanTag) {
        try {
            System.out.println("Received clan tag (path): " + clanTag);
            return clashService.fetchCurrentWar(clanTag);
        } catch (IOException e) {
            System.err.println("Error details: " + e.getMessage());
            return List.of(); // Return empty list on error
        } catch (Exception e) {
            System.err.println("General error: " + e.getMessage());
            return List.of(); // Return empty list on error
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
}
