# Android 12+ OPPO Phone Compatibility Fix

## 🚨 Issue: App Crashes on OPPO Android 12+

The app opens and immediately closes on OPPO phones running Android 12+ due to:
- Aggressive battery optimization
- ColorOS security restrictions
- Android 12+ permission changes

## ✅ Applied Fixes

### 1. **AndroidManifest.xml Updates**
- ✅ Added battery optimization permissions
- ✅ Added Android 12+ backup rules
- ✅ Fixed intent filters
- ✅ Set portrait orientation lock
- ✅ Updated target SDK to 34

### 2. **Battery Optimization Handler**
- ✅ Created `MainActivity.kt` with OPPO-specific optimizations
- ✅ Auto-requests battery optimization disable
- ✅ Fallback to app settings if needed

### 3. **Build Configuration**
- ✅ Updated to Kotlin 2.1.0
- ✅ Set Java 17 compatibility
- ✅ Updated to Android SDK 36 (latest)
- ✅ Added Android 12+ vector drawable support

## 📱 Manual Setup Required on OPPO Phone

After installing the APK, you need to configure these settings:

### Step 1: Battery Optimization
1. Go to **Settings** → **Battery** → **Battery Optimization**
2. Find "Crown Security" app
3. Select **"Don't optimize"** or **"Allow"**

### Step 2: App Permissions
1. Go to **Settings** → **Apps** → **Crown Security**
2. Go to **Permissions**
3. Enable all requested permissions

### Step 3: Auto-Start Management (OPPO Specific)
1. Go to **Settings** → **Battery** → **App Auto-Start Management**
2. Find "Crown Security"
3. Enable **"Allow auto-start"**

### Step 4: Background App Refresh
1. Go to **Settings** → **Battery** → **Background App Refresh**
2. Find "Crown Security"
3. Set to **"Allow"**

### Step 5: ColorOS App Lock (If Available)
1. Go to **Settings** → **Privacy** → **App Lock**
2. Make sure "Crown Security" is NOT locked
3. Or disable App Lock entirely

## 🔧 Alternative Installation Method

If the app still crashes, try this installation sequence:

### Method 1: ADB Installation
```cmd
# Enable Developer Options first on phone
# Enable USB Debugging
# Connect phone to computer
adb install app-release.apk
```

### Method 2: APK with Debug Info
Use the debug APK for troubleshooting:
```cmd
flutter build apk --debug --dart-define=API_BASE_URL=https://crown-security-fullstack.onrender.com/api/v1
```

## 🚨 OPPO ColorOS Specific Commands

### Force Stop Battery Optimization
1. Dial `*#*#4636#*#*` (may not work on all OPPO models)
2. Or go to **Phone Manager** → **Permission Privacy** → **Auto-Start Management**

### Alternative Settings Path
- **Phone Manager** → **Apps** → **Crown Security** → **Permissions**
- **Security Center** → **App Management** → **Crown Security**

## 📋 Troubleshooting Checklist

If app still crashes, check:

- [ ] **Internet Connection**: Ensure phone has internet access
- [ ] **Storage Space**: Free up at least 500MB space
- [ ] **ColorOS Version**: Update to latest ColorOS if possible
- [ ] **App Permissions**: All permissions granted
- [ ] **Battery Optimization**: Disabled for Crown Security
- [ ] **Auto-Start**: Enabled for Crown Security
- [ ] **Background Refresh**: Allowed for Crown Security

## 🔄 Rebuild Instructions

After applying fixes, rebuild the APK:

```cmd
# Clean previous build
flutter clean

# Build with optimizations (Android SDK 36)
flutter build apk --release \
  --dart-define=API_BASE_URL=https://crown-security-personal.onrender.com/api/v1 \
  --build-name=1.0.1 \
  --build-number=2
```

## 📱 Test on OPPO Device

1. **Install APK**: Copy and install on OPPO phone
2. **First Launch**: App will request battery optimization disable
3. **Grant Permission**: Allow the request when prompted
4. **Configure Settings**: Follow manual setup steps above
5. **Test Login**: Use `client@crown.local` / `Pass@123`

## 💡 Pro Tips for OPPO Phones

1. **Restart After Installation**: Reboot phone after installing and configuring
2. **Disable Power Saving**: Turn off power saving mode temporarily
3. **Update ColorOS**: Ensure latest ColorOS version
4. **Clear Cache**: Clear phone cache partition if available
5. **Factory Reset**: Last resort - backup and factory reset phone

## 🆘 If Nothing Works

Try these last resort options:

1. **Use Web Version**: Access via browser at production URL
2. **Different Device**: Test on non-OPPO Android device
3. **Debug Version**: Use debug APK for detailed error logs
4. **Contact OPPO**: Report compatibility issue to OPPO support
