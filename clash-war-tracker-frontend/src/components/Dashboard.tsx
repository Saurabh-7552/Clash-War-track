import { useState, useEffect } from 'react';
import type { PlayerWarResult } from '../types/PlayerWarResult';
import { warResultsApi } from '../services/api';

function Dashboard() {
  const [results, setResults] = useState<PlayerWarResult[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const [fetching, setFetching] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const fetchResults = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await warResultsApi.getAllResults();
      setResults(data);
    } catch (err) {
      setError('Failed to fetch war results. Make sure the backend is running on http://localhost:8080');
      console.error('Error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await fetchResults();
    setRefreshing(false);
  };

  const handleFetchWarData = async () => {
    try {
      setFetching(true);
      setError(null);
      
      // Get stored clan ID
      const storedClanId = localStorage.getItem('clanId');
      if (!storedClanId) {
        setError('No clan ID found. Please set up your clan first.');
        return;
      }
      
      // Remove # from stored clan ID for API call
      const clanId = storedClanId.replace('#', '');
      
      // Fetch new war data from the API
      const newData = await warResultsApi.fetchCurrentWar(clanId);
      
      if (newData && newData.length > 0) {
        // Refresh the results to show the new data
        await fetchResults();
        setError(null);
        setSuccessMessage(`Successfully fetched ${newData.length} war results!`);
        // Clear success message after 3 seconds
        setTimeout(() => setSuccessMessage(null), 3000);
      } else {
        setError('No war data found. The clan might not be in war currently.');
      }
    } catch (err) {
      setError('Failed to fetch war data. Make sure the backend is running and the clan tag is correct.');
      console.error('Error fetching war data:', err);
    } finally {
      setFetching(false);
    }
  };

  useEffect(() => {
    fetchResults();
  }, []);

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  return (
    <div className="dashboard">
      <div className="dashboard-container">
        {/* Header */}
        <div className="header">
          <div className="header-title">
            <h1>⚔️ WAR ANALYTICS</h1>
          </div>
          <p className="header-subtitle">
            Real-time Clash of Clans War Tracking
          </p>
          
          {/* Action Buttons */}
          <div className="action-buttons">
            <button
              onClick={handleRefresh}
              disabled={refreshing}
              className="btn btn-primary"
            >
              <span className={refreshing ? 'spinner' : ''}>
                {refreshing ? '⟳' : '🔄'}
              </span>
              <span>{refreshing ? 'Refreshing...' : 'Refresh Data'}</span>
            </button>
            
            <button
              onClick={handleFetchWarData}
              disabled={fetching}
              className="btn btn-secondary"
            >
              <span className={fetching ? 'spinner' : ''}>
                {fetching ? '⟳' : '⚡'}
              </span>
              <span>{fetching ? 'Fetching...' : 'Fetch War Data'}</span>
            </button>
          </div>
        </div>

        {/* Success Message */}
        {successMessage && (
          <div className="success-message">
            <div className="success-icon">✅</div>
            <div className="success-text">{successMessage}</div>
          </div>
        )}

        {/* Main Content */}
        <div className="main-content">
          {loading ? (
            <div className="loading">
              <div className="loading-spinner">
                <div className="spinner"></div>
              </div>
              <div className="loading-text">Loading War Results...</div>
              <p className="loading-subtitle">Fetching the latest battle data from Clash of Clans API</p>
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
          ) : results.length === 0 ? (
            <div className="empty">
              <div className="empty-icon">
                <span>📊</span>
              </div>
              <div className="empty-title">No War Data Found</div>
              <p className="empty-subtitle">
                Fetch some war data to see results here
              </p>
              <button 
                onClick={handleFetchWarData}
                disabled={fetching}
                className="btn btn-empty"
              >
                <span className={fetching ? 'spinner' : ''}>
                  {fetching ? '⟳' : '⚡'}
                </span>
                <span>{fetching ? 'Fetching...' : 'Fetch War Data'}</span>
              </button>
            </div>
          ) : (
            <>
              {/* Stats */}
              <div className="stats">
                <div className="stat-card">
                  <div className="stat-icon">📊</div>
                  <div className="stat-value">{results.length}</div>
                  <div className="stat-label">Total Results</div>
                </div>
                <div className="stat-card">
                  <div className="stat-icon">⭐</div>
                  <div className="stat-value">
                    {results.length > 0 ? Math.round(results.reduce((sum, r) => sum + r.stars, 0) / results.length * 10) / 10 : 0}
                  </div>
                  <div className="stat-label">Avg Stars</div>
                </div>
                <div className="stat-card">
                  <div className="stat-icon">⚔️</div>
                  <div className="stat-value">
                    {results.length > 0 ? new Set(results.map(r => r.warId)).size : 0}
                  </div>
                  <div className="stat-label">Unique Wars</div>
                </div>
              </div>

              {/* Results Table */}
              <div className="table-container">
                <table className="table">
                  <thead className="table-header">
                    <tr>
                      <th>👤 Player</th>
                      <th>🆔 War ID</th>
                      <th>⭐ Stars</th>
                      <th>📅 Date</th>
                    </tr>
                  </thead>
                  <tbody>
                    {results.map((result, index) => (
                      <tr key={result.id || `result-${index}`} className="table-row">
                        <td className="table-cell">
                          <div className="player-info">
                            <div className="player-avatar">
                              {result.playerName.charAt(0).toUpperCase()}
                            </div>
                            <span className="player-name">{result.playerName}</span>
                          </div>
                        </td>
                        <td className="table-cell">
                          <div className="war-id">
                            <span className="war-id-text">
                              {result.warId.substring(0, 8)}...
                            </span>
                          </div>
                        </td>
                        <td className="table-cell">
                          <div className="stars-info">
                            <div className="stars-icon">⭐</div>
                            <span className="stars-value">{result.stars}</span>
                            {result.stars >= 6 && (
                              <span className="excellent-badge">EXCELLENT</span>
                            )}
                          </div>
                        </td>
                        <td className="table-cell">
                          <div className="date-text">
                            {result.createdAt ? formatDate(result.createdAt) : 'Just fetched'}
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
            Real-time Clash of Clans war tracking 🚀
          </p>
        </div>
      </div>
    </div>
  );
}

export default Dashboard;