package com.example.clashwartrackerbackend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PlayerWarResultDto {
    private String clanName;
    private String playerName;
    private String warId;
    private int stars;
}
