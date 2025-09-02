@echo off
echo ===============================================
echo  Crown Security - Android Production Build
echo ===============================================

cd app\crown_security

echo.
echo 1. Cleaning previous builds...
flutter clean

echo.
echo 2. Getting dependencies...
flutter pub get

echo.
echo 3. Building production APK for clients...
echo Connecting to Render.com production API...
echo Using Android SDK 36 for latest compatibility...
flutter build apk --release ^
  --dart-define=API_BASE_URL=https://crown-security-personal.onrender.com/api/v1 ^
  --build-name=1.0.1 ^
  --build-number=2

echo.
echo Note: If you get Kotlin version warnings, you can use this alternative command:
echo flutter build apk --release --android-skip-build-dependency-validation ^
echo   --dart-define=API_BASE_URL=https://crown-security-fullstack.onrender.com/api/v1 ^
echo   --build-name=1.0.0 --build-number=1

echo.
echo ===============================================
echo  Build Complete!
echo ===============================================
echo.
echo APK Location: app\crown_security\build\app\outputs\flutter-apk\app-release.apk
echo.
echo Installation Instructions:
echo 1. Copy the APK to your Android device
echo 2. Enable "Install from unknown sources" in device settings
echo 3. Tap the APK file to install
echo 4. The app is configured for CLIENT login only
echo 5. Admins must use the web version
echo.
echo Note: This APK connects to Render.com production server
echo Production API: https://crown-security-personal.onrender.com/api/v1
echo.
pause
