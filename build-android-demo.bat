@echo off
echo ===============================================
echo  Crown Security - Android Demo Build
echo ===============================================

cd app\crown_security

echo.
echo 1. Cleaning previous builds...
flutter clean

echo.
echo 2. Getting dependencies...
flutter pub get

echo.
echo 3. Building demo APK (connects to local server)...
flutter build apk --release ^
  --dart-define=API_BASE_URL=http://192.168.0.174:3000/api/v1 ^
  --build-name=1.0.0 ^
  --build-number=1

echo.
echo ===============================================
echo  Demo Build Complete!
echo ===============================================
echo.
echo APK Location: app\crown_security\build\app\outputs\flutter-apk\app-release.apk
echo.
echo Demo Instructions:
echo 1. Make sure your local server is running on port 3000
echo 2. Update the IP address (192.168.0.174) in this script to your computer's IP
echo 3. Ensure your phone and computer are on the same network
echo 4. Copy the APK to your Android device and install
echo 5. The app will connect to your local development server
echo.
echo Client Login Credentials:
echo - Use any CLIENT role account from your database
echo - Admins will be redirected to use web version
echo.
pause
