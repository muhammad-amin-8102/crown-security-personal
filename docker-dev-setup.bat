@echo off
REM Crown Security API - Docker Development Setup for Windows
echo 🐳 Crown Security Docker Development Setup
echo ==========================================

REM Check if Flutter web build exists
if not exist "backend\public\admin\index.html" (
    echo 📱 Building Flutter web app first...
    call build-web.bat
    if %errorlevel% neq 0 (
        echo ❌ Flutter web build failed
        exit /b 1
    )
) else (
    echo ✅ Flutter web build found
)

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
echo 🌐 Admin Portal: http://localhost:3000/admin
echo 🏥 API Health: http://localhost:3000/health
echo 📊 API Base: http://localhost:3000/api/v1
echo 💾 Database: localhost:5432
echo.
echo 📝 Useful commands:
echo    docker-compose logs -f          # View logs
echo    docker-compose exec backend sh  # Access backend container
echo    docker-compose down             # Stop services
echo    build-web.bat                   # Rebuild Flutter web
