# Full-Stack Deployment Guide
# Deploy Flutter Web + Backend API as Single Container

## Deployment Architecture
```
Single Container:
├── Node.js 22 Backend (Port 10000)
├── API Routes (/api/v1/*)
├── Admin Portal (/admin/*)
└── Health Check (/health)
```

## Build Requirements
- **Flutter**: 3.24.3+ (Dart SDK 3.7.2+)
- **Node.js**: 22.x (Latest LTS)
- **PostgreSQL**: 15+

## Deployment Steps

### Option 1: Manual Render.com Deployment

1. **Prepare Repository**
   ```cmd
   git add .
   git commit -m "Full-stack deployment ready"
   git push origin main
   ```

2. **Create New Web Service on Render.com**
   - Go to https://dashboard.render.com
   - Click "New +" → "Web Service"
   - Connect your GitHub repository: `crown-security-personal`
   - Configure:
     - Name: `crown-security-fullstack`
     - Environment: `Docker`
     - Dockerfile Path: `./Dockerfile`
     - Docker Context: `./` (root directory)

3. **Environment Variables**
   ```
   NODE_ENV=production
   PORT=10000
   JWT_ACCESS_TTL=2592000
   JWT_REFRESH_TTL=2592000
   APP_NAME=Crown Security Full-Stack
   FRONTEND_URL=https://your-app-name.onrender.com
   
   # Database (from your existing PostgreSQL service)
   DATABASE_URL=postgresql://username:password@host:port/database
   ```

4. **Deploy**
   - Click "Create Web Service"
   - Render will automatically build using the root Dockerfile

### Option 2: Infrastructure as Code

1. **Use render-fullstack.yaml**
   ```cmd
   render deploy --file render-fullstack.yaml
   ```

## What Happens During Deployment

### Build Process (Multi-Stage)
1. **Flutter Build**: Uses Flutter 3.24.3 with Dart SDK 3.7.2+ to compile web app
2. **Backend Build**: Uses Node.js 22 (latest) to install dependencies
3. **Final Assembly**: Combines everything into Alpine Linux production container

### Container Structure
```
/app/
├── src/                 # Backend API code
├── config/              # Database configuration
├── models/              # Sequelize models
├── public/admin/        # Flutter web files (from build)
├── package.json         # Node.js dependencies
└── node_modules/        # Installed packages
```

### Runtime Behavior
- **Backend API**: Serves at `/api/v1/*`
- **Admin Portal**: Serves Flutter web at `/admin/*`
- **Health Check**: Available at `/health`
- **Root Route**: Redirects to `/admin`

## Advantages of Full-Stack Deployment

✅ **Single Container**: Easier management and deployment  
✅ **No CORS Issues**: Same domain for frontend and backend  
✅ **Shared Resources**: One database, one SSL certificate  
✅ **Cost Effective**: Single Render.com service instead of two  
✅ **Simplified URLs**: 
- Admin Portal: `https://your-app.onrender.com/admin`
- API: `https://your-app.onrender.com/api/v1`

## Accessing Your App

After deployment:
- **Admin Portal**: `https://your-app-name.onrender.com/admin`
- **API Health**: `https://your-app-name.onrender.com/health`
- **API Endpoints**: `https://your-app-name.onrender.com/api/v1/*`

## Troubleshooting

### Build Issues
```bash
# Check build logs in Render dashboard
# Common issues:

# 1. Flutter SDK version mismatch
# Error: "Because crown_security requires SDK version ^3.7.2, version solving failed"
# Solution: Dockerfile now uses Flutter 3.24.3 with Dart SDK 3.7.2+

# 2. Node.js dependency issues - check package.json
# 3. Docker context issues - ensure all files are in git
```

### Runtime Issues
```bash
# Check application logs in Render dashboard
# Health check: curl https://your-app.onrender.com/health
# Admin portal: check browser console for errors
```

## Monitoring

- **Health Check**: Automatic via `/health` endpoint
- **Logs**: Available in Render dashboard
- **Performance**: Single container metrics
- **Database**: Separate PostgreSQL service monitoring
