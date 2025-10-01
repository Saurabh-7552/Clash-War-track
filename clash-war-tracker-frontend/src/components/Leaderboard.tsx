import { useState, useEffect } from 'react';
import type { LeaderboardEntry } from '../types/LeaderboardEntry';
import { warResultsApi } from '../services/api';

function Leaderboard() {
  const [leaderboard, setLeaderboard] = useState<LeaderboardEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  const fetchLeaderboard = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await warResultsApi.getLeaderboard();
      setLeaderboard(data);
    } catch (err) {
      setError('Failed to fetch leaderboard. Make sure the backend is running on http://localhost:8080');
      console.error('Error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await fetchLeaderboard();
    setRefreshing(false);
  };

  useEffect(() => {
    fetchLeaderboard();
  }, []);

  const getRankIcon = (index: number) => {
    switch (index) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return (index + 1).toString();
    }
  };

  const getRankColor = (index: number) => {
    switch (index) {
      case 0:
        return '#fbbf24';
      case 1:
        return '#9ca3af';
      case 2:
        return '#f97316';
      default:
        return '#ffffff';
    }
  };

  return (
    <div className="dashboard">
      <div className="dashboard-container">
        {/* Header */}
        <div className="header">
          <div className="header-title">
            <h1>🏆 LEADERBOARD</h1>
          </div>
          <p className="header-subtitle">
            Top Players by Total Stars
          </p>
          
          {/* Refresh Button */}
          <button
            onClick={handleRefresh}
            disabled={refreshing}
            className="btn btn-primary"
          >
            <span className={refreshing ? 'spinner' : ''}>
              {refreshing ? '⟳' : '🔄'}
            </span>
            <span>{refreshing ? 'Refreshing...' : 'Refresh Leaderboard'}</span>
          </button>
        </div>

        {/* Main Content */}
        <div className="main-content">
          {loading ? (
            <div className="loading">
              <div className="loading-spinner">
                <div className="spinner"></div>
              </div>
              <div className="loading-text">Loading Leaderboard...</div>
              <p className="loading-subtitle">Calculating top performers</p>
              <div className="loading-dots">
                <div className="dot"></div>
                <div className="dot"></div>
                <div className="dot"></div>
              </div>
            </div>
          ) : error ? (
            <div className="error">
              <div className="error-icon">
                <span>⚠️</span>
              </div>
              <div className="error-message">{error}</div>
              <div className="error-buttons">
                <button 
                  onClick={handleRefresh}
                  className="btn btn-error"
                >
                  🔄 Retry Connection
                </button>
                <button 
                  onClick={() => window.location.reload()} 
                  className="btn btn-gray"
                >
                  🔄 Reload Page
                </button>
              </div>
            </div>
          ) : leaderboard.length === 0 ? (
            <div className="empty">
              <div className="empty-icon">
                <span>📊</span>
              </div>
              <div className="empty-title">No Leaderboard Data</div>
              <p className="empty-subtitle">
                Fetch some war data from the backend to populate the leaderboard.
              </p>
              <button 
                onClick={() => window.open('http://localhost:8080/api/fetch-currentwar?clanTag=2GC8P2L88', '_blank')}
                className="btn btn-empty"
              >
                ⚡ Fetch War Data
              </button>
            </div>
          ) : (
            <>
              {/* Leaderboard Stats */}
              <div className="stats">
                <div className="stat-card">
                  <div className="stat-icon">👥</div>
                  <div className="stat-value">{leaderboard.length}</div>
                  <div className="stat-label">Total Players</div>
                </div>
                <div className="stat-card">
                  <div className="stat-icon">⭐</div>
                  <div className="stat-value">
                    {leaderboard.reduce((sum, entry) => sum + entry.totalStars, 0)}
                  </div>
                  <div className="stat-label">Total Stars</div>
                </div>
                <div className="stat-card">
                  <div className="stat-icon">👑</div>
                  <div className="stat-value">
                    {leaderboard.length > 0 ? leaderboard[0].totalStars : 0}
                  </div>
                  <div className="stat-label">Highest Score</div>
                </div>
              </div>

              {/* Leaderboard Table */}
              <div className="table-container">
                <table className="table">
                  <thead className="table-header">
                    <tr>
                      <th># Rank</th>
                      <th>👤 Player</th>
                      <th>⭐ Total Stars</th>
                      <th>📊 Progress</th>
                    </tr>
                  </thead>
                  <tbody>
                    {leaderboard.map((entry, index) => (
                      <tr key={entry.playerName} className="table-row">
                        <td className="table-cell">
                          <div style={{ color: getRankColor(index), fontSize: '1.5rem', fontWeight: 'bold' }}>
                            {getRankIcon(index)}
                          </div>
                        </td>
                        <td className="table-cell">
                          <div className="player-info">
                            <div 
                              className="player-avatar"
                              style={{
                                backgroundColor: index === 0 ? '#fbbf24' : 
                                               index === 1 ? '#9ca3af' : 
                                               index === 2 ? '#f97316' : '#3b82f6'
                              }}
                            >
                              {entry.playerName.charAt(0).toUpperCase()}
                            </div>
                            <span className="player-name">{entry.playerName}</span>
                          </div>
                        </td>
                        <td className="table-cell">
                          <div className="stars-info">
                            <div className="stars-icon">⭐</div>
                            <span className="stars-value">{entry.totalStars}</span>
                          </div>
                        </td>
                        <td className="table-cell">
                          <div style={{ width: '100%', backgroundColor: '#374151', borderRadius: '0.5rem', height: '0.75rem' }}>
                            <div
                              style={{
                                background: 'linear-gradient(45deg, #fbbf24, #f97316)',
                                height: '0.75rem',
                                borderRadius: '0.5rem',
                                width: `${(entry.totalStars / (leaderboard.length > 0 ? leaderboard[0].totalStars : 1)) * 100}%`,
                                transition: 'all 0.5s ease-out'
                              }}
                            ></div>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </div>

        {/* Footer */}
        <div className="footer">
          <p className="footer-text">
            Track your clan's performance and rise to the top! 🚀
          </p>
        </div>
      </div>
    </div>
  );
}

export default Leaderboard;