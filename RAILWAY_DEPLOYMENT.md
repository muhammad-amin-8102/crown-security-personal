# Crown Security API - Railway.com Deployment Guide

## Prerequisites
1. GitHub account
2. Railway.com account
3. Your code pushed to a GitHub repository

## Step-by-Step Deployment

### 1. Prepare Your Repository
```bash
# Push your backend code to GitHub
cd backend
git add .
git commit -m "Prepare for Railway deployment"
git push origin main
```

### 2. Deploy on Railway.com

1. **Go to Railway.com**
   - Visit https://railway.app
   - Sign in with your GitHub account

2. **Create New Project**
   - Click "New Project"
   - Choose "Deploy from GitHub repo"
   - Select your repository
   - Choose the `backend` folder if it's in a monorepo

3. **Add PostgreSQL Database**
   - In your project dashboard, click "New"
   - Select "Database"
   - Choose "PostgreSQL"
   - Railway will automatically provide a `DATABASE_URL`

### 3. Configure Environment Variables

In Railway dashboard, go to your service → Variables tab and add:

**Required Variables:**
```
NODE_ENV=production
JWT_ACCESS_SECRET=your_super_secure_jwt_access_secret_here_railway
JWT_REFRESH_SECRET=your_super_secure_jwt_refresh_secret_here_railway
JWT_ACCESS_TTL=2592000
JWT_REFRESH_TTL=2592000
```

**Optional Variables:**
```
FRONTEND_URL=https://your-flutter-app-domain.com
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM=your-email@gmail.com
APP_NAME=Crown Security API
APP_VERSION=1.0.0
```

### 4. Database Setup

The deployment will automatically:
- Run database migrations
- Seed initial data
- Create necessary tables

### 5. Domain Configuration

Railway provides a domain like: `https://your-project-name.railway.app`

### 6. Test Your Deployment

1. **Health Check**
   - Visit: `https://your-project-name.railway.app/health`
   - Should return: `{"ok":true,"name":"Crown Security API",...}`

2. **API Test**
   - Visit: `https://your-project-name.railway.app/api/v1/users`
   - Should require authentication

### 7. Update Flutter App

Update your Flutter app's API base URL:

```dart
// In your API configuration
class Api {
  static const String baseUrl = 'https://your-project-name.railway.app/api/v1';
  // ... rest of your API class
}
```

## Troubleshooting

### Check Logs
- In Railway dashboard → your service → "Logs" tab
- Look for any error messages during startup

### Common Issues

1. **Database Connection Errors**
   - Ensure PostgreSQL service is running
   - Check DATABASE_URL is automatically set

2. **Migration Errors**
   - Check logs for specific migration issues
   - May need to manually run: `npm run db:migrate`

3. **JWT Errors**
   - Ensure JWT_ACCESS_SECRET and JWT_REFRESH_SECRET are set
   - Use strong, unique secrets for production

## Environment Variables Reference

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| NODE_ENV | Yes | Environment mode | `production` |
| JWT_ACCESS_SECRET | Yes | JWT signing secret | `your_secure_secret_here` |
| JWT_REFRESH_SECRET | Yes | JWT refresh secret | `your_refresh_secret_here` |
| JWT_ACCESS_TTL | No | JWT expiry (seconds) | `2592000` (30 days) |
| FRONTEND_URL | No | Allowed CORS origins | `https://yourapp.com` |
| EMAIL_* | No | Email configuration | For password reset |

## Post-Deployment

1. **Test all API endpoints**
2. **Update Flutter app configuration**
3. **Test mobile app with production API**
4. **Set up monitoring/alerts** (optional)

## Support

- Railway Docs: https://docs.railway.app
- Railway Discord: https://discord.gg/railway
- Crown Security API Health: `https://your-project.railway.app/health`
