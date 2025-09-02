# Crown Security - Local Development Guide

This guide will help you set up and run the Crown Security application locally on your Windows machine.

## 📋 Prerequisites

### Required Software
1. **Docker Desktop** (Recommended - Easiest setup)
   - Download from: https://www.docker.com/products/docker-desktop
   - Make sure it's running before starting

2. **For Manual Setup** (Alternative):
   - **Node.js 18+** - Download from: https://nodejs.org/
   - **Flutter SDK 3.35.2+** - Install from: https://flutter.dev/docs/get-started/install
   - **PostgreSQL 15+** - Download from: https://www.postgresql.org/download/

### Verify Installations
```cmd
# Check Docker
docker --version
docker-compose --version

# Check Node.js (if doing manual setup)
node --version
npm --version

# Check Flutter (if doing manual setup)
flutter --version
flutter doctor
```

## 🚀 Quick Start (Docker - Recommended)

### 1. Start the Application
```cmd
# Navigate to project directory
cd c:\Users\Admin\Downloads\Archive\projects\crown_security

# Start all services (PostgreSQL + Full-Stack App)
docker-compose up -d

# View logs to monitor startup
docker-compose logs -f
```

### 2. Access the Application
- **Admin Portal**: http://localhost:3000/admin
- **API Health Check**: http://localhost:3000/api/health
- **API Debug Info**: http://localhost:3000/debug

### 3. Default Login Credentials
- **Email**: `admin@crown.local`
- **Password**: `Pass@123`

### 4. Stop the Application
```cmd
# Stop all services
docker-compose down

# Stop and remove all data (complete reset)
docker-compose down -v
```

## 🛠️ Manual Setup (Alternative)

### 1. Setup PostgreSQL Database
```cmd
# Create database (using PostgreSQL command line)
psql -U postgres
CREATE DATABASE crown_security;
CREATE USER app_user WITH PASSWORD 'app_pass';
GRANT ALL PRIVILEGES ON DATABASE crown_security TO app_user;
\q
```

### 2. Setup Backend
```cmd
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Create environment file
copy .env.example .env

# Edit .env file with your database settings:
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=crown_security
# DB_USER=app_user
# DB_PASS=app_pass

# Run database migrations and seeds
npm run db:migrate
npm run db:seed

# Start backend server
npm run dev
```

### 3. Setup Flutter Web
```cmd
# Navigate to Flutter directory
cd app\crown_security

# Get Flutter dependencies
flutter pub get

# Build web version
flutter build web --release --dart-define=API_BASE_URL=/api/v1 --base-href=/admin/

# Copy build to backend public folder
xcopy build\web\* ..\..\backend\public\admin\ /E /Y
```

### 4. Access the Application
- **Admin Portal**: http://localhost:3000/admin
- **Backend API**: http://localhost:3000/api/health

## 🔧 Development Commands

### Docker Commands
```cmd
# View running containers
docker ps

# View application logs
docker-compose logs -f app

# View database logs
docker-compose logs -f postgres

# Restart just the application
docker-compose restart app

# Rebuild application (after code changes)
docker-compose build app
docker-compose up -d
```

### Backend Development
```cmd
cd backend

# Start in development mode (auto-reload)
npm run dev

# Run database operations
npm run db:migrate        # Run migrations
npm run db:seed          # Run seeders
npm run db:reset         # Reset database

# Test database connection
npm run test-db

# View available scripts
npm run
```

### Flutter Development
```cmd
cd app\crown_security

# Run in development mode (hot reload)
flutter run -d chrome --web-port 8080

# Build web version
flutter build web --release --dart-define=API_BASE_URL=/api/v1 --base-href=/admin/

# Analyze code
flutter analyze

# Run tests
flutter test
```

## 📁 Project Structure Overview

```
crown_security/
├── app/crown_security/           # Flutter Web Application
│   ├── lib/                     # Dart source code
│   ├── web/                     # Web-specific assets
│   └── pubspec.yaml             # Flutter dependencies
├── backend/                     # Node.js API Server
│   ├── src/                     # Application source
│   │   ├── app.js              # Express app configuration
│   │   └── server.js           # Server startup
│   ├── models/                  # Sequelize models
│   ├── config/                  # Database configuration
│   ├── migrations/              # Database migrations
│   ├── seeders/                 # Database seeders
│   └── public/admin/            # Flutter web build output
├── docker-compose.yml           # Local development environment
├── Dockerfile                   # Application container
└── build-web.bat               # Flutter build script (Windows)
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Docker not starting
```cmd
# Check if Docker Desktop is running
docker version

# If Docker is not running, start Docker Desktop application
```

#### 2. bcrypt module errors (Fixed in v1.1)
```cmd
# If you see "Error loading shared library bcrypt_lib.node: Exec format error"
# This is fixed in the current Dockerfile, but if it persists:

# Clean rebuild everything
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

#### 3. Docker compose version warning (Fixed)
```cmd
# Remove orphaned containers if you see warnings about version or orphans
docker-compose down --remove-orphans
docker-compose up -d
```

#### 4. Database connection issues
```cmd
# Check if PostgreSQL container is running
docker-compose ps

# View database logs
docker-compose logs postgres

# Reset database
docker-compose down -v
docker-compose up -d
```

#### 3. Flutter build issues
```cmd
# Clean Flutter cache
cd app\crown_security
flutter clean
flutter pub get

# Rebuild web
flutter build web --release --dart-define=API_BASE_URL=/api/v1 --base-href=/admin/
```

#### 5. Bills/SOA module not found (Fixed in v1.2)
```cmd
# If you see "404 Not Found" for Bills/SOA page
# This was fixed by adding the missing GET route for bills

# The fix is already applied, but if you encounter similar issues:
docker-compose build app
docker-compose up -d

# Verify the fix
curl http://localhost:3000/api/v1/bills
```

#### 6. Admin login not working
```cmd
# Check if seeders ran successfully
docker-compose logs app | findstr "seed"

# Manually trigger seeding
curl -X POST http://localhost:3000/seed
```

### Debug Endpoints

- **Health Check**: `GET http://localhost:3000/api/health`
- **Database Debug**: `GET http://localhost:3000/debug`
- **Manual Seeding**: `POST http://localhost:3000/seed`

### Log Locations

- **Application Logs**: `docker-compose logs app`
- **Database Logs**: `docker-compose logs postgres`
- **Combined Logs**: `docker-compose logs -f`

## 🔄 Development Workflow

### Making Changes to Flutter
1. Edit Flutter code in `app/crown_security/lib/`
2. Rebuild web: `flutter build web --release --dart-define=API_BASE_URL=/api/v1 --base-href=/admin/`
3. Copy to backend: `xcopy build\web\* ..\..\backend\public\admin\ /E /Y`
4. Restart app container: `docker-compose restart app`

### Making Changes to Backend
1. Edit backend code in `backend/src/`
2. If using Docker: `docker-compose restart app`
3. If running manually: Changes auto-reload with `npm run dev`

### Database Changes
1. Create migration: `npx sequelize-cli migration:create --name your-migration-name`
2. Edit migration file in `backend/migrations/`
3. Run migration: `npm run db:migrate` or restart Docker

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. View application logs: `docker-compose logs -f`
3. Verify prerequisites are installed correctly
4. Try a complete reset: `docker-compose down -v && docker-compose up -d`

## 🎯 Next Steps

After successful local setup:
1. Explore the admin portal at http://localhost:3000/admin
2. Check API documentation at http://localhost:3000/debug
3. Review the codebase structure
4. Start developing new features!
