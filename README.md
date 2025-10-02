# ⚔️ Clash War Tracker

A comprehensive full-stack application for tracking Clash of Clans war statistics with real-time analytics and leaderboards.

![Clash War Tracker](https://img.shields.io/badge/Spring%20Boot-3.3.0-brightgreen) ![React](https://img.shields.io/badge/React-18.2.0-blue) ![TypeScript](https://img.shields.io/badge/TypeScript-5.0.0-blue) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15.0-blue)

## 🚀 Features

- **Real-time War Data**: Fetch current war information from Clash of Clans API
- **Player Analytics**: Track individual player performance and star counts
- **Multi-Clan Support**: Unique player identification by clan name + player name
- **Leaderboards**: Rank players by total stars earned across all wars
- **Dynamic Clan Setup**: Users can input their own clan ID with validation
- **Modern UI**: Beautiful, responsive interface with custom CSS styling
- **Database Persistence**: Store war results in PostgreSQL database
- **RESTful API**: Complete backend API for data management
- **AWS Cloud Deployment**: Production-ready deployment on AWS EC2

## 🏗️ Architecture

### Backend (Spring Boot)
- **Framework**: Spring Boot 3.3.0 with Java 21
- **Database**: PostgreSQL with JPA/Hibernate
- **External API**: Clash of Clans API integration
- **Dependencies**: Spring Web, Spring Data JPA, OkHttp, Gson, Lombok

### Frontend (React + TypeScript)
- **Framework**: React 18.2.0 with TypeScript
- **Build Tool**: Vite for fast development and building
- **Styling**: Custom CSS with modern animations and gradients
- **Routing**: React Router DOM for navigation
- **HTTP Client**: Axios for API communication

## 📸 Screenshots

### Welcome Page - Clan Setup
![Welcome Page Screenshot](https://github.com/Saurabh-7552/Clash-War-track/blob/master/screenshots/welcome.png)
*The initial setup page where users enter their clan ID with step-by-step instructions on how to find their clan tag in Clash of Clans*

### Dashboard - War Analytics
![Dashboard Screenshot](https://github.com/Saurabh-7552/Clash-War-track/blob/master/screenshots/dashboard.png)
*Real-time war data with player statistics and performance metrics showing 225 total results, 3.3 average stars, and detailed player war results table*

### Leaderboard - Player Rankings
![Leaderboard Screenshot](https://github.com/Saurabh-7552/Clash-War-track/blob/master/screenshots/leaderboard.png)
*Ranked leaderboard showing top performers by total stars with 45 total players, 745 total stars, and highest score of 30 stars*

## 🛠️ Installation & Setup

### Prerequisites
- Java 21 or higher
- Node.js 18+ and npm
- PostgreSQL 12+
- Maven 3.6+

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Saurabh-7552/Clash-War-track.git
   cd Clash-War-track
   ```

2. **Configure Database**
   - Create PostgreSQL database: `clashwar`
   - Update `src/main/resources/application.properties`:
   ```properties
   spring.datasource.url=jdbc:postgresql://localhost:5432/clashwar
   spring.datasource.username=your_username
   spring.datasource.password=your_password
   ```

3. **Add API Key**
   - Get your Clash of Clans API key from [Supercell Developer Portal](https://developer.clashofclans.com/)
   - Update `clash.api.key` in `application.properties`

4. **Run Backend**
   ```bash
   mvn spring-boot:run
   ```
   

### Frontend Setup

1. **Navigate to frontend directory**
   ```bash
   cd clash-war-tracker-frontend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Start development server**
   ```bash
   npm run dev
   ```
  

## 📚 API Endpoints

### War Data
- `GET /api/fetch-currentwar?clanTag={TAG}` - Fetch current war data for specific clan
- `GET /api/fetch-currentwar/{clanTag}` - Alternative path variable endpoint
- `GET /api/results` - Get all stored war results
- `GET /api/leaderboard` - Get player leaderboard ranked by total stars
- `DELETE /api/clear-all-data` - Clear all war data from database

### Health Check
- `GET /api/health` - Application health check endpoint
- `GET /api/hello` - Basic hello endpoint

### Response Examples

**Successful War Data:**
```json
[
  {
    "clanName": "Elite Warriors",
    "playerName": "PlayerOne",
    "warId": "war_20251002_123456",
    "stars": 3
  }
]
```

**No War Status:**
```json
[
  {
    "clanName": null,
    "playerName": "NO_WAR",
    "warId": "NO_WAR", 
    "stars": -1
  }
]
```

## 🎯 Usage

### Initial Setup
1. **Visit the Application**: Navigate to http://13.48.112.177 (or localhost for development)
2. **Enter Clan ID**: On first visit, you'll see the clan setup page
3. **Find Your Clan Tag**: Follow the in-app instructions to locate your clan tag in Clash of Clans
4. **Validate Clan**: Enter your clan tag (e.g., #2GC8P2L88) and click "Start Tracking"
5. **Automatic Redirect**: Upon successful validation, you'll be redirected to the dashboard

### Fetching War Data
1. **Dashboard Access**: After clan setup, you'll see the main dashboard
2. **Fetch War Data**: Click "Fetch War Data" button to get current war information
3. **API Integration**: The system calls the Clash of Clans API with your clan tag
4. **Data Display**: War results are displayed in a comprehensive table with clan and player information
5. **Auto-Save**: All data is automatically saved to the PostgreSQL database
6. **No War Handling**: If your clan isn't in war, you'll see a "not in war" message

### Viewing Leaderboards
1. **Navigation**: Click on "Leaderboard" in the top navigation
2. **Rankings**: View players ranked by total stars across all wars
3. **Clan Context**: See which clan each player belongs to
4. **Real-time Updates**: Leaderboard updates automatically as new war data is fetched

### Changing Clans
1. **Change Clan Button**: Click "Change Clan" in the top-left navigation
2. **New Setup**: Enter a different clan tag to track multiple clans
3. **Data Separation**: Each clan's data is tracked separately in the system

## 🗄️ Database Schema

### PlayerWarResult Entity
```sql
CREATE TABLE player_war_results (
    id BIGSERIAL PRIMARY KEY,
    clan_name VARCHAR(255) NOT NULL,
    player_name VARCHAR(255) NOT NULL,
    war_id VARCHAR(255) NOT NULL,
    stars INTEGER NOT NULL,
    created_at TIMESTAMP
);
```

**Key Features:**
- **Unique Player Identification**: Combination of `clan_name` + `player_name` ensures players with same names from different clans are tracked separately
- **War Deduplication**: `war_id` prevents duplicate war data from being stored
- **Comprehensive Tracking**: Stores clan context alongside player performance

## 🔧 Configuration

### Backend Configuration (`application.properties`)
```properties
# Database Configuration
spring.datasource.url=jdbc:postgresql://localhost:5432/clashwar
spring.datasource.username=postgres
spring.datasource.password=yourpassword
spring.jpa.hibernate.ddl-auto=update

# API Configuration
clash.api.key=your_api_key_here
```

### Frontend Configuration
- API base URL: `http://localhost:8080/api`
- Timeout: 10 seconds
- Content-Type: `application/json`

## 🚀 Deployment

### 🌐 Live Demo
The application is deployed on AWS EC2 with Elastic IP:
- **Live Application**: http://13.48.112.177
- **API Health Check**: http://13.48.112.177/api/health

### AWS EC2 Deployment (Production)

The application is deployed on AWS EC2 with the following architecture:
- **EC2 Instance**: t3.micro (Amazon Linux 2)
- **Elastic IP**: 13.48.112.177
- **Database**: PostgreSQL (local on EC2)
- **Reverse Proxy**: Nginx
- **Process Management**: systemd services

#### Deployment Architecture
```
Internet → Nginx (Port 80) → {
  Frontend: Python HTTP Server (Port 3000)
  Backend API: Spring Boot (Port 8080)
} → PostgreSQL (Port 5432)
```

#### Services Configuration
- **Backend Service**: `clash-tracker-backend.service`
- **Frontend Service**: `clash-tracker-frontend.service`
- **Database**: PostgreSQL with `clash_tracker` database
- **Web Server**: Nginx with reverse proxy configuration

### Local Development Deployment

#### Backend Deployment
1. Build the JAR file:
   ```bash
   mvn clean package
   ```

2. Run the application:
   ```bash
   java -jar target/clash-war-tracker-backend-0.0.1-SNAPSHOT.jar
   ```

#### Frontend Deployment
1. Build for production:
   ```bash
   npm run build
   ```

2. Serve the `dist` folder with any static file server

## 🧪 Testing

### Backend Testing
```bash
# Run all tests
mvn test

# Run specific test class
mvn test -Dtest=ClashServiceTest
```

### Frontend Testing
```bash
# Run unit tests
npm test

# Run with coverage
npm run test:coverage
```

## 📊 Performance

- **Backend**: Handles 100+ concurrent requests
- **Database**: Optimized queries with proper indexing
- **Frontend**: Lazy loading and efficient state management
- **API**: Rate limiting and error handling

## 🔒 Security

- API key stored in environment variables
- Input validation and sanitization
- CORS configuration for cross-origin requests
- SQL injection prevention with JPA

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Saurabh**
- GitHub: [@Saurabh-7552](https://github.com/Saurabh-7552)
- Project: [Clash War Tracker](https://github.com/Saurabh-7552/Clash-War-track)

## 🙏 Acknowledgments

- [Supercell](https://supercell.com/) for the Clash of Clans API
- [Spring Boot](https://spring.io/projects/spring-boot) for the backend framework
- [React](https://reactjs.org/) for the frontend framework
- [PostgreSQL](https://www.postgresql.org/) for the database

## 📞 Support

If you have any questions or need help, please:
1. Check the [Issues](https://github.com/Saurabh-7552/Clash-War-track/issues) page
2. Create a new issue with detailed description
3. Contact the maintainer

---

**Made with ❤️ for the Clash of Clans community**
