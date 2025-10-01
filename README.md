# ⚔️ Clash War Tracker

A comprehensive full-stack application for tracking Clash of Clans war statistics with real-time analytics and leaderboards.

![Clash War Tracker](https://img.shields.io/badge/Spring%20Boot-3.3.0-brightgreen) ![React](https://img.shields.io/badge/React-18.2.0-blue) ![TypeScript](https://img.shields.io/badge/TypeScript-5.0.0-blue) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15.0-blue)

## 🚀 Features

- **Real-time War Data**: Fetch current war information from Clash of Clans API
- **Player Analytics**: Track individual player performance and star counts
- **Leaderboards**: Rank players by total stars earned across all wars
- **Modern UI**: Beautiful, responsive interface with custom CSS styling
- **Database Persistence**: Store war results in PostgreSQL database
- **RESTful API**: Complete backend API for data management

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
   Backend will be available at `http://localhost:8080`

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
   Frontend will be available at `http://localhost:5173`

## 📚 API Endpoints

### War Data
- `GET /api/fetch-currentwar?clanTag={TAG}` - Fetch current war data
- `GET /api/results` - Get all stored war results
- `GET /api/leaderboard` - Get player leaderboard

### Health Check
- `GET /api/hello` - Basic health check endpoint

## 🎯 Usage

### Fetching War Data
1. Navigate to the Dashboard
2. Click "Fetch War Data" button
3. The system will call the Clash of Clans API
4. War results will be displayed in the table
5. Data is automatically saved to the database

### Viewing Leaderboards
1. Click on "Leaderboard" in the navigation
2. View ranked players by total stars
3. Refresh to get the latest rankings

## 🗄️ Database Schema

### PlayerWarResult Entity
```sql
CREATE TABLE player_war_results (
    id BIGSERIAL PRIMARY KEY,
    player_name VARCHAR(255),
    war_id VARCHAR(255),
    stars INTEGER,
    created_at TIMESTAMP
);
```

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

### Backend Deployment
1. Build the JAR file:
   ```bash
   mvn clean package
   ```

2. Run the application:
   ```bash
   java -jar target/clash-war-tracker-backend-0.0.1-SNAPSHOT.jar
   ```

### Frontend Deployment
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
