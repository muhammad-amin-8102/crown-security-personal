@echo off
echo ========================================
echo Crown Security - Local Development
echo ========================================
echo.

echo Checking Docker...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker is not installed or not running
    echo Please install Docker Desktop from: https://www.docker.com/products/docker-desktop
    echo.
    pause
    exit /b 1
)

echo ✅ Docker is available
echo.

echo Starting Crown Security application...
echo This will start PostgreSQL database and the full-stack application
echo.

docker-compose up -d

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo 🎉 Crown Security is starting up!
    echo ========================================
    echo.
    echo 📊 Admin Portal: http://localhost:3000/admin
    echo 🏥 Health Check: http://localhost:3000/api/health
    echo 🔍 Debug Info:   http://localhost:3000/debug
    echo.
    echo 🔑 Default Login Credentials:
    echo    Email:    admin@crownsecurity.com
    echo    Password: Admin@2025!
    echo.
    echo ⏳ Please wait 30-60 seconds for the application to fully start
    echo.
    echo 📊 To view logs:     docker-compose logs -f
    echo 🛑 To stop:         docker-compose down
    echo 🔄 To restart:      docker-compose restart
    echo.
    
    choice /C YN /M "Open admin portal in browser now"
    if errorlevel 2 goto :end
    if errorlevel 1 start http://localhost:3000/admin
    
) else (
    echo.
    echo ❌ Failed to start the application
    echo.
    echo Try these troubleshooting steps:
    echo 1. Make sure Docker Desktop is running
    echo 2. Check if ports 3000 and 5432 are available
    echo 3. Run: docker-compose down -v
    echo 4. Run this script again
    echo.
)

:end
echo.
echo Press any key to exit...
pause >nul
