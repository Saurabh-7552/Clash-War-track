import axios from 'axios';
import type { PlayerWarResult } from '../types/PlayerWarResult';
import type { LeaderboardEntry } from '../types/LeaderboardEntry';

const API_BASE_URL = 'http://localhost:8080/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add request interceptor for better error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.code === 'ECONNABORTED') {
      console.error('Request timeout - Backend might be down');
    } else if (error.response?.status === 0) {
      console.error('Network error - Backend not reachable');
    }
    return Promise.reject(error);
  }
);

export const warResultsApi = {
  // Test backend connection
  testConnection: async (): Promise<boolean> => {
    try {
      const response = await api.get('/health');
      return response.status === 200;
    } catch (error) {
      console.error('Backend connection test failed:', error);
      return false;
    }
  },

  // Fetch all war results
  getAllResults: async (): Promise<PlayerWarResult[]> => {
    try {
      const response = await api.get<PlayerWarResult[]>('/results');
      return response.data;
    } catch (error) {
      console.error('Error fetching war results:', error);
      throw error;
    }
  },

  // Fetch current war data for a clan
  fetchCurrentWar: async (clanTag: string): Promise<PlayerWarResult[]> => {
    try {
      const response = await api.get<PlayerWarResult[]>(`/fetch-currentwar?clanTag=${encodeURIComponent(clanTag)}`);
      // Transform DTO to entity format for frontend consistency
      return response.data.map((dto: any) => ({
        id: undefined,
        clanName: dto.clanName,
        playerName: dto.playerName,
        warId: dto.warId,
        stars: dto.stars,
        createdAt: undefined
      }));
    } catch (error) {
      console.error('Error fetching current war:', error);
      throw error;
    }
  },

  // Fetch leaderboard data
  getLeaderboard: async (): Promise<LeaderboardEntry[]> => {
    try {
      const response = await api.get<LeaderboardEntry[]>('/leaderboard');
      return response.data;
    } catch (error) {
      console.error('Error fetching leaderboard:', error);
      throw error;
    }
  },
};

export default api;
