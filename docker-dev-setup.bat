@echo off
REM Crown Security API - Docker Development Setup for Windows
echo 🐳 Crown Security Docker Development Setup
echo ==========================================

REM Build and start services
echo 📦 Building Docker images...
docker-compose build

echo 🚀 Starting services...
docker-compose up -d

REM Wait for database to be ready
echo ⏳ Waiting for database to be ready...
timeout /t 10

REM Run migrations
echo 🔄 Running database migrations...
docker-compose exec backend npm run db:migrate

REM Show status
echo ✅ Setup complete!
echo.
echo 🌐 API available at: http://localhost:3000
echo 🏥 Health check: http://localhost:3000/health
echo 💾 Database: localhost:5432
echo.
echo 📝 Useful commands:
echo    docker-compose logs -f          # View logs
echo    docker-compose exec backend sh  # Access backend container
echo    docker-compose down             # Stop services
