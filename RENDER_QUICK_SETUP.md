# Crown Security API - Render.com Quick Setup

## 🚀 Quick Deployment Steps

### 1. Database Setup
1. Go to [Render.com](https://render.com) → New → PostgreSQL
2. Name: `crown-security-db`
3. Note the connection details

### 2. Web Service Setup
1. New → Web Service
2. Connect GitHub repo
3. Configuration:
   - **Name**: `crown-security-api`
   - **Environment**: Node
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Root Directory**: `backend` (if monorepo)

### 3. Environment Variables
Copy from `.env.render` to your service environment:

**Critical Variables:**
```
NODE_ENV=production
DATABASE_URL=[from your PostgreSQL service]
JWT_ACCESS_SECRET=[generate strong secret]
JWT_REFRESH_SECRET=[generate strong secret]
```

### 4. Deploy
- Push to GitHub → Auto-deploys
- Check logs for any issues
- Test: `https://your-service.onrender.com/health`

## 💡 Pro Tips

- **Free Tier**: Services sleep after 15 min inactivity
- **Database**: Copy exact connection string from Render dashboard
- **Migrations**: Run automatically on startup
- **Logs**: Check Render dashboard for errors

## 🔗 URLs After Deployment
- **API**: `https://crown-security-api.onrender.com`
- **Health**: `https://crown-security-api.onrender.com/health`
- **Admin**: Update Flutter app with new API URL
