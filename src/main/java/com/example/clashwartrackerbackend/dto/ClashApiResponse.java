package com.example.clashwartrackerbackend.dto;

import lombok.Data;
import java.util.List;

@Data
public class ClashApiResponse {
    private String state;
    private int teamSize;
    private String preparationStartTime;
    private String startTime;
    private String endTime;
    private ClanInfo clan;
    private ClanInfo opponent;
    
    @Data
    public static class ClanInfo {
        private String tag;
        private String name;
        private int level;
        private int attacks;
        private int stars;
        private double destructionPercentage;
        private List<Member> members;
    }
    
    @Data
    public static class Member {
        private String tag;
        private String name;
        private int townhallLevel;
        private int mapPosition;
        private List<Attack> attacks;
        private Attack bestOpponentAttack;
    }
    
    @Data
    public static class Attack {
        private String attackerTag;
        private String defenderTag;
        private int stars;
        private double destructionPercentage;
        private int order;
    }
}
