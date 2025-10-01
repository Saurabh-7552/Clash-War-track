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

export const warResultsApi = {
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
      return response.data;
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
