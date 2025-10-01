import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { warResultsApi } from '../services/api';

function ClanSetup() {
  const [clanId, setClanId] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [showInstructions, setShowInstructions] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!clanId.trim()) {
      setError('Please enter a clan ID');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      // Test the clan ID by trying to fetch war data
      await warResultsApi.fetchCurrentWar(clanId.trim());
      
      // If we get here, the clan ID is valid
      // Store the clan ID in localStorage
      localStorage.setItem('clanId', clanId.trim());
      
      // Show success message briefly
      setSuccessMessage('Clan ID validated successfully! Redirecting...');
      
      // Navigate to dashboard after a short delay
      setTimeout(() => {
        navigate('/');
        // Reload the page to update the app state
        window.location.reload();
      }, 1500);
    } catch (err) {
      setError('Invalid clan ID. Please check the clan tag and try again.');
      console.error('Clan validation error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleClanIdChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    let value = e.target.value;
    // Remove any existing # and add it automatically
    value = value.replace(/#/g, '');
    if (value) {
      value = '#' + value;
    }
    setClanId(value);
    setError(null);
  };

  return (
    <div className="clan-setup">
      <div className="clan-setup-container">
        {/* Header */}
        <div className="setup-header">
          <div className="setup-logo">
            <div className="logo-icon">⚔️</div>
            <div>
              <h1>CLASH WAR TRACKER</h1>
              <p>Enter Your Clan Information</p>
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div className="setup-content">
          <div className="setup-card">
            <div className="setup-title">
              <h2>🏰 Welcome to Clash War Tracker</h2>
              <p>Enter your clan ID to start tracking war performance</p>
            </div>

            {/* Instructions */}
            <div className="instructions-section">
              <button
                type="button"
                onClick={() => setShowInstructions(!showInstructions)}
                className="instructions-toggle"
              >
                <span>📋</span>
                <span>How to find your Clan ID?</span>
                <span className={showInstructions ? 'arrow-up' : 'arrow-down'}>▼</span>
              </button>

              {showInstructions && (
                <div className="instructions-content">
                  <div className="instruction-steps">
                    <div className="step">
                      <div className="step-number">1</div>
                      <div className="step-content">
                        <h4>Open Clash of Clans</h4>
                        <p>Launch the Clash of Clans game on your device</p>
                      </div>
                    </div>
                    <div className="step">
                      <div className="step-number">2</div>
                      <div className="step-content">
                        <h4>Go to Your Clan</h4>
                        <p>Tap on your clan name or clan badge</p>
                      </div>
                    </div>
                    <div className="step">
                      <div className="step-number">3</div>
                      <div className="step-content">
                        <h4>Find the Clan Tag</h4>
                        <p>Look for the clan tag (starts with #) at the top of the clan page</p>
                        <div className="clan-tag-example">
                          <span>Example: #2GC8P2L88</span>
                        </div>
                      </div>
                    </div>
                    <div className="step">
                      <div className="step-number">4</div>
                      <div className="step-content">
                        <h4>Copy the Tag</h4>
                        <p>Copy the entire clan tag including the # symbol</p>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Clan ID Input Form */}
            <form onSubmit={handleSubmit} className="clan-form">
              <div className="form-group">
                <label htmlFor="clanId" className="form-label">
                  🏰 Clan ID
                </label>
                <div className="input-container">
                  <input
                    type="text"
                    id="clanId"
                    value={clanId}
                    onChange={handleClanIdChange}
                    placeholder="#2GC8P2L88"
                    className={`form-input ${error ? 'error' : ''}`}
                    disabled={loading}
                  />
                  <div className="input-hint">
                    Enter your clan tag (e.g., #2GC8P2L88)
                  </div>
                </div>
              </div>

              {error && (
                <div className="error-message">
                  <span className="error-icon">⚠️</span>
                  <span>{error}</span>
                </div>
              )}

              {successMessage && (
                <div className="success-message">
                  <span className="success-icon">✅</span>
                  <span>{successMessage}</span>
                </div>
              )}

              <button
                type="submit"
                disabled={loading || !clanId.trim()}
                className="submit-button"
              >
                {loading ? (
                  <>
                    <span className="spinner">⟳</span>
                    <span>Validating Clan ID...</span>
                  </>
                ) : (
                  <>
                    <span>🚀</span>
                    <span>Start Tracking</span>
                  </>
                )}
              </button>
            </form>

            {/* Features Preview */}
            <div className="features-preview">
              <h3>What you'll get:</h3>
              <div className="features-grid">
                <div className="feature">
                  <span className="feature-icon">📊</span>
                  <span>Real-time War Analytics</span>
                </div>
                <div className="feature">
                  <span className="feature-icon">🏆</span>
                  <span>Player Leaderboards</span>
                </div>
                <div className="feature">
                  <span className="feature-icon">⭐</span>
                  <span>Star Performance Tracking</span>
                </div>
                <div className="feature">
                  <span className="feature-icon">📈</span>
                  <span>Historical War Data</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default ClanSetup;
