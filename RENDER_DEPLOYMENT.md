# Crown Security API - Render.com Deployment Guide

## Prerequisites
1. GitHub account
2. Render.com account (free tier available)
3. Your code pushed to a GitHub repository

## Step-by-Step Deployment

### 1. Prepare Your Repository
```bash
# Push your backend code to GitHub
cd backend
git add .
git commit -m "Prepare for Render deployment"
git push origin main
```

### 2. Deploy on Render.com

1. **Go to Render.com**
   - Visit https://render.com
   - Sign in with your GitHub account

2. **Create New Web Service**
   - Click "New +"
   - Select "Web Service"
   - Connect your GitHub repository
   - Select your repository and the `backend` folder (if monorepo)

3. **Configure Web Service**
   - **Name**: `crown-security-api`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: Free (or paid for production)

4. **Add PostgreSQL Database**
   - Click "New +"
   - Select "PostgreSQL"
   - **Name**: `crown-security-db`
   - **Plan**: Free (or paid for production)
   - Note the connection details for environment variables

### 3. Configure Environment Variables

In Render dashboard, go to your web service → Environment tab and add:

**Required Variables:**
```
NODE_ENV=production
DATABASE_URL=postgresql://username:password@hostname:port/database
JWT_ACCESS_SECRET=your_super_secure_jwt_access_secret_here_render
JWT_REFRESH_SECRET=your_super_secure_jwt_refresh_secret_here_render
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

**Database URL Format:**
- Get from your PostgreSQL service dashboard
- Format: `postgresql://username:password@hostname:port/database`

### 4. Database Setup

The deployment will automatically:
- Run database migrations
- Seed initial data
- Create necessary tables

### 5. Domain Configuration

Render provides a domain like: `https://crown-security-api.onrender.com`

### 6. Test Your Deployment

1. **Health Check**
   - Visit: `https://crown-security-api.onrender.com/health`
   - Should return: `{"ok":true,"name":"Crown Security API",...}`

2. **API Test**
   - Visit: `https://crown-security-api.onrender.com/api/v1/users`
   - Should require authentication

### 7. Update Flutter App

Update your Flutter app's API base URL:

```dart
// In your API configuration
class Api {
  static const String baseUrl = 'https://crown-security-api.onrender.com/api/v1';
  // ... rest of your API class
}
```

## Troubleshooting

### Check Logs
- In Render dashboard → your service → "Logs" tab
- Look for any error messages during startup

### Common Issues

1. **Database Connection Errors**
   - Ensure PostgreSQL service is running
   - Check DATABASE_URL format is correct
   - Verify database credentials

2. **Migration Errors**
   - Check logs for specific migration issues
   - Ensure DATABASE_URL is properly set
   - May need to manually run migrations

3. **JWT Errors**
   - Ensure JWT_ACCESS_SECRET and JWT_REFRESH_SECRET are set
   - Use strong, unique secrets for production

4. **Cold Start Issues**
   - Free tier services sleep after 15 minutes of inactivity
   - First request after sleep may take 30+ seconds
   - Consider upgrading to paid plan for production

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

- Render Docs: https://render.com/docs
- Render Community: https://community.render.com
- Crown Security API Health: `https://crown-security-api.onrender.com/health`

## Render.com Free Tier Limitations

- **Web Services**: Sleep after 15 minutes of inactivity
- **PostgreSQL**: 1GB storage, 1 month retention
- **Bandwidth**: 100GB/month
- **Build Time**: 500 hours/month

For production use, consider upgrading to paid plans for:
- Always-on services (no sleep)
- More database storage
- Faster build times
- Custom domains
