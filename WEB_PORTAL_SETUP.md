# 🌐 Crown Security Web Portal Configuration

## 📋 Overview
Your Crown Security project is configured as a full-stack web application with two deployment options:
- **Docker Deployment**: Complete containerized solution
- **Non-Docker Deployment**: Traditional server setup
- **Architecture**: Flutter web admin portal + Node.js API backend

## 🏗️ Full-Stack Architecture

```
https://your-domain.com/
├── /                     → Redirects to /admin
├── /admin               → Flutter Web Admin Portal
├── /admin/*             → Flutter Web Routes (SPA)
├── /api/v1              → Backend API
├── /api/v1/auth/login   → API Authentication
└── /health              → Health Check
```

## 🚀 Deployment Options

### Option 1: Docker Deployment (Recommended)

#### Local Development with Docker
```bash
# Build and run full-stack application
docker-compose up -d

# Access:

## 🔧 Quick Commands

### Development
```bash
# Docker (Recommended)
docker-compose up -d

# Non-Docker
build-web.bat && cd backend && npm run dev
```

### Production Deployment
```bash
# Docker (Render.com)
git push origin main
# Then deploy via Render dashboard using render-fullstack.yaml

# Non-Docker (VPS/Server)
# Follow NON_DOCKER_DEPLOYMENT.md guide
```

## 🌐 Access URLs

After deployment:
- **Admin Portal**: `https://your-domain.com/admin`
- **API Docs**: `https://your-domain.com/api/v1`
- **Health Check**: `https://your-domain.com/health`

## � Documentation

- `FULLSTACK_DEPLOYMENT.md` - Complete Docker deployment guide
- `NON_DOCKER_DEPLOYMENT.md` - Traditional server deployment
- `render-fullstack.yaml` - Render.com configuration
- `docker-compose.yml` - Local development setup

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
