# Crown Security API - Docker Deployment Guide

## 🐳 Docker Architecture Overview

Your Crown Security project is now fully containerized with:
- **Backend API**: Node.js/Express in Docker container
- **Database**: PostgreSQL (external on Render or local container)
- **Production Ready**: Multi-stage builds, health checks, security

## 📁 Docker Files Structure

```
crown_security/
├── docker-compose.yml              # Local development
├── docker-compose.prod.yml         # Production configuration
├── docker-dev-setup.sh/.bat       # Setup scripts
└── backend/
    ├── Dockerfile                  # Production container
    ├── .dockerignore              # Docker ignore rules
    ├── .env.docker                # Local Docker env
    └── .env.render.docker         # Render Docker env
```

## 🚀 Local Development

### Option 1: Quick Setup (Windows)
```bash
# Run the setup script
docker-dev-setup.bat
```

### Option 2: Manual Setup
```bash
# Build and start services
docker-compose up -d

# Run migrations
docker-compose exec backend npm run db:migrate

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## 🌐 Render.com Docker Deployment

### 1. Prepare Repository
```bash
# Ensure all Docker files are committed
git add .
git commit -m "Add Docker configuration"
git push origin main
```

### 2. Deploy on Render.com

#### A. Create PostgreSQL Database
1. Go to Render Dashboard → New → PostgreSQL
2. **Name**: `crown-security-db`
3. **Plan**: Free
4. Wait for status: "Available"
5. Copy the **External Connection** URL

#### B. Create Docker Web Service
1. **New** → **Web Service**
2. **Connect Repository**: Your GitHub repo
3. **Configuration**:
   - **Name**: `crown-security-api`
   - **Environment**: `Docker`
   - **Dockerfile Path**: `./backend/Dockerfile`
   - **Docker Context**: `./backend`
   - **Plan**: Free

### 3. Environment Variables
Set these in Render Web Service → Environment:

```env
NODE_ENV=production
DATABASE_URL=postgresql://user:pass@hostname.oregon-postgres.render.com:5432/db
JWT_ACCESS_SECRET=your_super_secure_secret_here
JWT_REFRESH_SECRET=your_super_secure_refresh_secret_here
JWT_ACCESS_TTL=2592000
JWT_REFRESH_TTL=2592000
```

### 4. Deploy and Monitor
- Render will automatically build the Docker image
- Monitor logs for successful startup
- Health check: `https://your-service.onrender.com/health`

## 🔧 Docker Commands Reference

### Development
```bash
# Build image locally
npm run docker:build

# Start development environment
npm run docker:dev

# View logs
npm run docker:logs

# Stop all services
npm run docker:stop

# Access backend container
docker-compose exec backend sh

# Run migrations in container
docker-compose exec backend npm run db:migrate
```

### Production Testing
```bash
# Build production image
docker build -t crown-security-api ./backend

# Run with production config
docker-compose -f docker-compose.prod.yml up

# Test with external database
docker run -p 10000:10000 \
  -e DATABASE_URL="your_production_db_url" \
  -e JWT_ACCESS_SECRET="your_secret" \
  crown-security-api
```

## 🛡️ Security Features

- **Non-root user**: Container runs as `nodejs` user
- **Minimal image**: Alpine Linux base (smaller attack surface)
- **Health checks**: Built-in container health monitoring
- **Environment isolation**: Secrets via environment variables
- **Network isolation**: Custom Docker networks

## 🐛 Troubleshooting

### Container Won't Start
```bash
# Check container logs
docker-compose logs backend

# Check container status
docker-compose ps

# Rebuild image
docker-compose build --no-cache backend
```

### Database Connection Issues
```bash
# Test database connectivity
docker-compose exec backend npm run test-db

# Check PostgreSQL container
docker-compose logs postgres

# Verify environment variables
docker-compose exec backend env | grep DATABASE
```

### Render Deployment Issues
1. **Build Fails**: Check Dockerfile syntax and paths
2. **Health Check Fails**: Verify `/health` endpoint works
3. **Database Connection**: Ensure DATABASE_URL is correct format
4. **Port Issues**: Render uses PORT environment variable (usually 10000)

## 📊 Monitoring

### Health Checks
- **Local**: http://localhost:3000/health
- **Render**: https://your-service.onrender.com/health

### Logs
```bash
# Container logs
docker-compose logs -f backend

# Render logs
# Available in Render Dashboard → Your Service → Logs
```

## 🚀 Advantages of Docker Deployment

✅ **Consistent Environment**: Same container runs everywhere
✅ **Easy Scaling**: Render can scale Docker containers
✅ **Better Debugging**: Isolated environment with detailed logging
✅ **Production Parity**: Development matches production exactly
✅ **Health Monitoring**: Built-in health checks for reliability
✅ **Security**: Container isolation and non-root execution

Your Crown Security API is now production-ready with Docker! 🎉
