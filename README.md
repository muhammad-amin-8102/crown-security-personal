# Crown Security Management System

A full-stack web application for security company management with Flutter web frontend and Node.js backend.

## 🏗️ Architecture

```
Crown Security Full-Stack Application
├── Flutter Web Admin Portal (/admin)
├── Node.js REST API (/api/v1)
├── PostgreSQL Database
└── Docker Containerization
```

## 🚀 Quick Start

### Option 1: Docker (Recommended)
```bash
# Clone repository
git clone https://github.com/muhammad-amin-8102/crown-security-personal.git
cd crown-security-personal

# Start full-stack application
docker-compose up -d

# Access admin portal
open http://localhost:3000/admin
```

### Option 2: Manual Setup
```bash
# Build Flutter web
build-web.bat        # Windows
./build-web.sh       # Linux/Mac

# Start backend
cd backend
npm install
npm run dev

# Access admin portal
open http://localhost:3000/admin
```

## 🌐 Deployment

### Production (Render.com)
1. Push to GitHub
2. Create Web Service on Render.com
3. Use `render-fullstack.yaml` configuration
4. Deploy with Docker environment

### Traditional Server
Follow the comprehensive guide in `NON_DOCKER_DEPLOYMENT.md`

## 📁 Project Structure

```
crown_security/
├── app/crown_security/           # Flutter Web Application
│   ├── lib/                     # Dart source code
│   ├── web/                     # Web-specific assets
│   └── pubspec.yaml             # Flutter dependencies
├── backend/                     # Node.js API Server
│   ├── src/                     # Application source
│   ├── models/                  # Database models
│   ├── config/                  # Configuration files
│   ├── migrations/              # Database migrations
│   └── package.json             # Node.js dependencies
├── Dockerfile                   # Full-stack Docker build
├── docker-compose.yml           # Local development
├── render-fullstack.yaml        # Render.com deployment
└── build-web.bat/.sh           # Flutter build scripts
```

## 🔧 Features

### Admin Portal (Flutter Web)
- 📊 Dashboard with analytics
- 👥 User management
- 🏢 Site management
- ⏰ Shift scheduling
- 📝 Attendance tracking
- 💰 Payroll management
- 🚨 Incident reporting
- 📈 Training reports

### Backend API (Node.js)
- 🔐 JWT Authentication
- 📡 REST API endpoints
- 🗄️ PostgreSQL database
- 🔄 Database migrations
- 📧 Email notifications
- 🏥 Health monitoring
- 🛡️ Security middleware

## 🛠️ Technology Stack

- **Frontend**: Flutter Web (Dart)
- **Backend**: Node.js, Express.js
- **Database**: PostgreSQL with Sequelize ORM
- **Authentication**: JWT tokens
- **Deployment**: Docker, Render.com
- **Development**: Docker Compose

## 📚 Documentation

- [`FULLSTACK_DEPLOYMENT.md`](FULLSTACK_DEPLOYMENT.md) - Docker deployment guide
- [`NON_DOCKER_DEPLOYMENT.md`](NON_DOCKER_DEPLOYMENT.md) - Traditional server setup
- [`WEB_PORTAL_SETUP.md`](WEB_PORTAL_SETUP.md) - Web portal configuration

## 🌐 URLs

After deployment:
- **Admin Portal**: `https://your-domain.com/admin`
- **API Base**: `https://your-domain.com/api/v1`
- **Health Check**: `https://your-domain.com/health`

## 🔐 Environment Variables

### Required for Production
```env
NODE_ENV=production
PORT=10000
DATABASE_URL=postgresql://user:pass@host:port/db
JWT_ACCESS_SECRET=your_secure_secret
JWT_REFRESH_SECRET=your_secure_refresh_secret
FRONTEND_URL=https://your-domain.com
```

## 🚀 Development

### Prerequisites
- Node.js 18+
- Flutter SDK 3.0+
- PostgreSQL 15+
- Docker (optional)

### Local Development
```bash
# 1. Install dependencies
cd backend && npm install
cd ../app/crown_security && flutter pub get

# 2. Setup database
# Create PostgreSQL database and run migrations

# 3. Build and serve
docker-compose up -d
# OR
build-web.bat && cd backend && npm run dev
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is private and proprietary.

## 🆘 Support

For deployment issues, check the troubleshooting sections in the deployment guides:
- Docker issues → `FULLSTACK_DEPLOYMENT.md`
- Server issues → `NON_DOCKER_DEPLOYMENT.md`
- Web portal issues → `WEB_PORTAL_SETUP.md`
