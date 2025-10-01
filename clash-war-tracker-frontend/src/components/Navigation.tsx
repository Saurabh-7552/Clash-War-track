import { Link, useLocation } from 'react-router-dom';

function Navigation() {
  const location = useLocation();

  const isActive = (path: string) => {
    return location.pathname === path;
  };

  return (
    <nav className="navigation">
      <div className="nav-container">
        <div className="nav-content">
          {/* Left side - Change Clan Button */}
          <Link
            to="/setup"
            className="change-clan-btn"
          >
            <span>🏰</span>
            <span>Change Clan</span>
          </Link>

          {/* Center - Logo */}
          <Link to="/" className="logo">
            <div className="logo-icon">⚔️</div>
            <div>
              <div className="logo-text">CLASH WAR TRACKER</div>
              <div className="logo-subtitle">Real-time War Analytics</div>
            </div>
          </Link>

          {/* Right side - Navigation Links */}
          <div className="nav-links">
            <Link
              to="/"
              className={`nav-link ${isActive('/') ? 'active' : ''}`}
            >
              <span>📊</span>
              <span>Dashboard</span>
            </Link>
            <Link
              to="/leaderboard"
              className={`nav-link ${isActive('/leaderboard') ? 'active' : ''}`}
            >
              <span>🏆</span>
              <span>Leaderboard</span>
            </Link>
          </div>
        </div>
      </div>
    </nav>
  );
}

export default Navigation;
