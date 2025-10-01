package com.example.clashwartrackerbackend.service;

import com.example.clashwartrackerbackend.dto.ClashApiResponse;
import com.example.clashwartrackerbackend.dto.PlayerWarResultDto;
import com.example.clashwartrackerbackend.entity.PlayerWarResult;
import com.example.clashwartrackerbackend.repository.PlayerWarResultRepository;
import com.google.gson.Gson;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class ClashService {

    private static final Logger logger = LoggerFactory.getLogger(ClashService.class);
    private final OkHttpClient httpClient = new OkHttpClient();
    private final Gson gson = new Gson();

    @Autowired
    private PlayerWarResultRepository playerWarResultRepository;

    @Value("${clash.api.key:eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiIsImtpZCI6IjI4YTMxOGY3LTAwMDAtYTFlYi03ZmExLTJjNzQzM2M2Y2NhNSJ9.eyJpc3MiOiJzdXBlcmNlbGwiLCJhdWQiOiJzdXBlcmNlbGw6Z2FtZWFwaSIsImp0aSI6IjQxMWQyZDBhLTg0MWUtNDVhMi1hYzY1LTE0ZWU3MTUyZDc0YiIsImlhdCI6MTc1OTMwNDA1OCwic3ViIjoiZGV2ZWxvcGVyLzA3MzMzZTY3LTA4NTEtNTk5Ny1iZWEyLTA5ZDY2MjBlMDhiOCIsInNjb3BlcyI6WyJjbGFzaCJdLCJsaW1pdHMiOlt7InRpZXIiOiJkZXZlbG9wZXIvc2lsdmVyIiwidHlwZSI6InRocm90dGxpbmcifSx7ImNpZHJzIjpbIjE1Mi41OS4xMjAuMjQiXSwidHlwZSI6ImNsaWVudCJ9XX0.ZiaqBYmP2ckmXA7EjiXS4w9Mjtb-8FGHil_G-Farp_3tr_4z-NiupKuP899POcUC62zqTMt9quQ7-BMU2_JSbQ}")
    private String apiKey;

    public List<PlayerWarResultDto> fetchCurrentWar(String clanTag) throws IOException {
        // Ensure clan tag starts with # if it doesn't already
        if (!clanTag.startsWith("#")) {
            clanTag = "#" + clanTag;
        }
        
        // URL encode the clan tag for the API call
        String encodedClanTag = java.net.URLEncoder.encode(clanTag, "UTF-8");
        String url = "https://api.clashofclans.com/v1/clans/" + encodedClanTag + "/currentwar";
        
        logger.info("Making API call to: {}", url);

        Request request = new Request.Builder()
                .url(url)
                .addHeader("Authorization", "Bearer " + apiKey)
                .addHeader("Accept", "application/json")
                .build();

        try (Response response = httpClient.newCall(request).execute()) {
            String responseBody = response.body() != null ? response.body().string() : "No response body";
            
            if (!response.isSuccessful()) {
                logger.error("API Error - Code: {}, URL: {}, Response: {}", response.code(), url, responseBody);
                throw new IOException("API Error - Code: " + response.code() + ", Response: " + responseBody);
            }

            logger.info("Clash of Clans API Response: {}", responseBody);
            
            // Parse JSON response
            ClashApiResponse apiResponse = gson.fromJson(responseBody, ClashApiResponse.class);
            
            // Check if clan is in war
            if (!"inWar".equals(apiResponse.getState())) {
                logger.info("Clan is not in war. State: {}", apiResponse.getState());
                return new ArrayList<>();
            }
            
            // Generate war ID
            String warId = UUID.randomUUID().toString();
            
            // Extract player war results
            List<PlayerWarResultDto> playerResults = new ArrayList<>();
            
            // Process clan members
            if (apiResponse.getClan() != null && apiResponse.getClan().getMembers() != null) {
                for (ClashApiResponse.Member member : apiResponse.getClan().getMembers()) {
                    int totalStars = 0;
                    if (member.getAttacks() != null) {
                        for (ClashApiResponse.Attack attack : member.getAttacks()) {
                            totalStars += attack.getStars();
                        }
                    }
                    
                    playerResults.add(new PlayerWarResultDto(
                        member.getName(),
                        warId,
                        totalStars
                    ));
                }
            }
            
            logger.info("Extracted {} player war results", playerResults.size());
            
            // Save results to database
            List<PlayerWarResult> savedResults = new ArrayList<>();
            for (PlayerWarResultDto dto : playerResults) {
                PlayerWarResult entity = new PlayerWarResult();
                entity.setPlayerName(dto.getPlayerName());
                entity.setWarId(dto.getWarId());
                entity.setStars(dto.getStars());
                savedResults.add(playerWarResultRepository.save(entity));
            }
            
            logger.info("Saved {} player war results to database", savedResults.size());
            return playerResults;
        }
    }
}
