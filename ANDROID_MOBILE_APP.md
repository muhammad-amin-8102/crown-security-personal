# Crown Security - Android Mobile App Setup

## 📱 Mobile App Overview

The Android mobile app is designed specifically for **CLIENT** users only. Admin users must use the web version.

### App Features
- **Client-only access**: Only CLIENT role users can use the mobile app
- **Admin redirection**: Admin users are automatically redirected to use the web version
- **Production ready**: Configured for production deployment with proper API endpoints
- **Secure**: Uses HTTPS for production API calls

## 🏗️ Building the APK

### For Production Deployment (Render.com)

The production APK is pre-configured to connect to your Render.com deployment:

1. **Run the production build**:
   ```cmd
   build-android-production.bat
   ```

   This will build an APK that connects to:
   ```
   https://crown-security-personal.onrender.com/api/v1
   ```

### For Demo/Testing (Local Server)

1. **Update your computer's IP** in `build-android-demo.bat`:
   ```batch
   --dart-define=API_BASE_URL=http://192.168.1.XXX:3000/api/v1
   ```

2. **Make sure local server is running**:
   ```cmd
   docker-compose up -d
   ```

3. **Run the demo build**:
   ```cmd
   build-android-demo.bat
   ```

## 📲 Installation Instructions

### 1. Locate the APK
After building, find the APK at:
```
app\crown_security\build\app\outputs\flutter-apk\app-release.apk
```

### 2. Install on Android Device
1. Copy the APK file to your Android device
2. Enable "Install from unknown sources" in device settings:
   - **Settings** → **Security** → **Unknown sources** (older Android)
   - **Settings** → **Apps** → **Special access** → **Install unknown apps** (newer Android)
3. Tap the APK file to install
4. Grant any required permissions

## 🔐 Login Credentials

### Client User (Mobile App)
- **Email**: `client@crown.local`
- **Password**: `Pass@123`
- **Role**: CLIENT

### Admin User (Web Only)
- **Email**: `admin@crown.local` 
- **Password**: `Pass@123`
- **Role**: ADMIN
- **Access**: Web version only at `http://localhost:3000/admin`

## 🔄 App Behavior

### Client Users
- Can login and access all client features
- Dashboard, site profile, attendance, expenses, etc.
- Full mobile experience

### Admin Users
- **Cannot use mobile app**
- Will see dialog: "Admin access is not available on mobile"
- Automatically logged out and redirected to login
- Must use web version for admin functions

## 🌐 API Configuration

### Production (Render.com)
```dart
// Configured in lib/core/api.dart
baseUrl: 'https://crown-security-personal.onrender.com/api/v1'
```

### Development/Demo
```dart
// For local testing
baseUrl: 'http://192.168.1.XXX:3000/api/v1'
```

## 🔧 Customization

### App Name & Package
- **App Name**: Crown Security (displayed on device)
- **Package**: `com.crowntech.security`
- **Version**: 1.0.0+1

### Branding
- App icon: Located in `android/app/src/main/res/mipmap-*/`
- App theme: Golden color scheme `#CFAE02`
- Splash screen: Launch theme configured

## 🚀 Deployment Checklist

### Before Building Production APK:
- [ ] Ensure Render.com deployment is active and accessible
- [ ] Test client login credentials work on production server
- [ ] Verify admin users are properly redirected
- [ ] Update app version in pubspec.yaml if needed
- [ ] Test APK on physical device with internet connection

### For Customer Demo:
- [ ] Build demo APK with local server IP
- [ ] Ensure local server is running and accessible
- [ ] Provide client login credentials
- [ ] Demonstrate client features
- [ ] Show admin redirection (if needed)

## 📱 Supported Features

### Client Dashboard
- ✅ Overview and statistics
- ✅ Quick actions
- ✅ Recent activities

### Site Management
- ✅ Site profile viewing
- ✅ Site information updates

### Attendance
- ✅ Check-in/check-out
- ✅ Attendance history
- ✅ Shift management

### Expenses & Reports
- ✅ Expense tracking
- ✅ Shift reports
- ✅ Training reports
- ✅ Bills and SOA viewing

### Other Features
- ✅ Salary disbursement info
- ✅ Complaints submission
- ✅ Rating and NPS
- ✅ Night rounds reporting

## 🐛 Troubleshooting

### Common Issues

#### 1. APK Won't Install
- Enable "Install from unknown sources"
- Clear device storage if needed
- Try reinstalling

#### 2. Login Fails
- Check internet connection
- Verify API URL is correct
- Check server is running and accessible

#### 3. Admin Can't Access
- **This is expected behavior**
- Admins must use web version
- Provide web URL for admin access

#### 4. Network Issues
- Ensure device and server on same network (demo)
- Check firewall settings
- Verify API endpoint is reachable

### Testing Connectivity

Test API connection:
```bash
# From your phone's browser, visit:
https://crown-security-personal.onrender.com/api/health

# Should return:
{"status":"ok","timestamp":"..."}
```

## 📞 Support

For issues:
1. Check troubleshooting section above
2. Verify server logs: `docker-compose logs -f`
3. Test API endpoints manually
4. Rebuild APK with correct configuration
