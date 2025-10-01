import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { useState, useEffect } from 'react';
import Navigation from './components/Navigation';
import Dashboard from './components/Dashboard';
import Leaderboard from './components/Leaderboard';
import ClanSetup from './components/ClanSetup';
import './styles/App.css';

function App() {
  const [hasClanId, setHasClanId] = useState<boolean | null>(null);

  useEffect(() => {
    // Check if user has a stored clan ID
    const storedClanId = localStorage.getItem('clanId');
    setHasClanId(!!storedClanId);
  }, []);

  // Show loading while checking for clan ID
  if (hasClanId === null) {
    return (
      <div className="app">
        <div className="loading-screen">
          <div className="loading-spinner">
            <div className="spinner"></div>
          </div>
          <div className="loading-text">Loading Clash War Tracker...</div>
        </div>
      </div>
    );
  }

  return (
    <Router>
      <div className="app">
        {hasClanId ? (
          <>
            <Navigation />
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/leaderboard" element={<Leaderboard />} />
              <Route path="/setup" element={<ClanSetup />} />
            </Routes>
          </>
        ) : (
          <Routes>
            <Route path="/setup" element={<ClanSetup />} />
            <Route path="*" element={<Navigate to="/setup" replace />} />
          </Routes>
        )}
      </div>
    </Router>
  );
}

export default App
