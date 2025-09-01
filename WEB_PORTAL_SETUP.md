# 🌐 Crown Security Web Portal Configuration

## 📋 Overview
Your Crown Security project is now configured as a full-stack web application:
- **Backend API**: Node.js/Express serving API at `/api/v1`
- **Admin Portal**: Flutter web app served at `/admin`
- **Single Domain**: Everything runs from one URL

## 🏗️ Architecture

```
https://your-domain.com/
├── /                     → Redirects to /admin
├── /admin               → Flutter Web Admin Portal
├── /admin/*             → Flutter Web Routes (SPA)
├── /api/v1              → Backend API
├── /api/v1/auth/login   → API Authentication
└── /health              → Health Check
```

## 🚀 Quick Setup

### Local Development
```bash
# 1. Build Flutter web app
build-web.bat          # Windows
./build-web.sh         # Linux/Mac

# 2. Start backend with web portal
cd backend
npm run dev

# 3. Access admin portal
# http://localhost:3000/admin
```

### Docker Development
```bash
# 1. Build Flutter web first
build-web.bat

# 2. Start Docker services
docker-compose up -d

# 3. Access admin portal
# http://localhost:3000/admin
```

## 🔧 Configuration Details

### Flutter Web API Configuration
- **Development**: Uses `http://localhost:3000/api/v1`
- **Production**: Uses relative URLs (`/api/v1`)
- **Web Detection**: Automatically detects web vs mobile
- **CORS Handling**: Configured for same-origin requests

### Backend Web Serving
- **Static Files**: Serves Flutter build from `/admin`
- **SPA Routing**: All `/admin/*` routes serve `index.html`
- **API Routes**: All `/api/v1/*` routes serve API
- **Security**: CSP headers configured for Flutter web

### Build Process
1. **Flutter Build**: Creates optimized web bundle
2. **Copy Assets**: Moves files to `backend/public/admin/`
3. **Backend Serve**: Express serves Flutter files

## 📁 File Structure

```
crown_security/
├── app/crown_security/           # Flutter source
│   ├── lib/core/api.dart        # Web-aware API config
│   └── .env.web                 # Web build config
├── backend/
│   ├── src/app.js               # Web serving config
│   ├── public/admin/            # Flutter web build
│   ├── Dockerfile               # Production (with Flutter)
│   └── Dockerfile.local         # Development (without Flutter)
├── build-web.sh/.bat            # Build scripts
└── docker-compose.yml           # Local development
```

## 🌐 Deployment Options

### Option 1: Manual Build + Deploy
```bash
# 1. Build Flutter web
build-web.bat

# 2. Deploy backend with Flutter files
# (Flutter files are in backend/public/admin/)
```

### Option 2: Docker with Multi-stage Build
```bash
# Dockerfile automatically builds Flutter and includes it
docker build -t crown-security-app ./backend
```

### Option 3: Render.com Docker Deployment
```bash
# Uses main Dockerfile with Flutter build stage
# Set environment variables in Render dashboard
```

## 🔧 Environment Variables

### Development (.env)
```env
NODE_ENV=development
PORT=3000
DB_HOST=localhost
# ... other backend vars
```

### Production (Render.com)
```env
NODE_ENV=production
DATABASE_URL=postgresql://...
FRONTEND_URL=https://your-app.onrender.com
# ... other backend vars
```

### Flutter Web Build
```env
API_BASE_URL=http://localhost:3000  # Development
# Production uses relative URLs automatically
```

## 🚨 Security Features

✅ **Content Security Policy**: Configured for Flutter web
✅ **CORS**: Same-origin policy for production
✅ **Static Files**: Served securely by Express
✅ **API Protection**: JWT authentication maintained
✅ **Route Protection**: SPA routing preserved

## 🧪 Testing

### Local Testing
```bash
# 1. Build and start
build-web.bat && cd backend && npm run dev

# 2. Test endpoints
curl http://localhost:3000/health           # Health check
curl http://localhost:3000/api/v1/users     # API (needs auth)
# http://localhost:3000/admin               # Admin portal
```

### Production Testing
```bash
# Test production build locally
NODE_ENV=production npm start
```

## 🔄 Development Workflow

1. **Flutter Development**: Make changes in `app/crown_security/`
2. **Build Web**: Run `build-web.bat` to update web files
3. **Backend Development**: Changes in `backend/` auto-reload
4. **Test**: Access `http://localhost:3000/admin`

## 🚀 Deployment to Render.com

1. **Push Code**: Ensure Flutter web build is included
2. **Docker Service**: Render will build using main Dockerfile
3. **Environment Variables**: Set in Render dashboard
4. **Access**: `https://your-service.onrender.com/admin`

## 💡 Pro Tips

- **Flutter Hot Reload**: Use `flutter run -d web-server --web-port 5000` for development
- **API Testing**: Use `/api/health` for quick API tests
- **Build Automation**: Set up CI/CD to auto-build Flutter web
- **Cache Busting**: Flutter builds include hash-based file names
- **Progressive Web App**: Flutter web builds are PWA-ready

Your Crown Security application is now a complete full-stack web application! 🎉
