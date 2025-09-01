@echo off
REM Flutter Web Build Script for Crown Security Admin Portal
echo 🌐 Building Crown Security Admin Portal for Web
echo ===============================================

REM Navigate to Flutter project
cd "%~dp0app\crown_security"

REM Check if Flutter is available
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed or not in PATH
    exit /b 1
)

echo ✅ Flutter found
flutter --version | findstr "Flutter"

REM Clean previous builds
echo 🧹 Cleaning previous builds...
flutter clean

REM Get dependencies
echo 📦 Getting Flutter dependencies...
flutter pub get

REM Build for web
echo 🏗️ Building Flutter web app...
flutter build web --release --dart-define=API_BASE_URL=%API_BASE_URL% --web-renderer canvaskit --output build/web

REM Copy to backend public directory
echo 📁 Copying build to backend...
set BACKEND_PUBLIC=..\..\backend\public\admin
if not exist "%BACKEND_PUBLIC%" mkdir "%BACKEND_PUBLIC%"
xcopy "build\web\*" "%BACKEND_PUBLIC%\" /E /Y

echo ✅ Web build completed successfully!
echo.
echo 🌐 Admin portal will be available at:
echo    Local: http://localhost:3000/admin
echo    Production: https://your-domain.com/admin
echo.
echo 📂 Files copied to: backend\public\admin\
