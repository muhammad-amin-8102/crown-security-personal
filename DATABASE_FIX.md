# 🚨 Fix Database Connection Error on Render

## Quick Fix Steps

### 1. Check DATABASE_URL Format
Your DATABASE_URL must include the port and full hostname:

**❌ Wrong Format:**
```
postgresql://user:pass@dpg-abc123-a/database
```

**✅ Correct Format:**
```
postgresql://user:pass@dpg-abc123-a.oregon-postgres.render.com:5432/database
```

### 2. Update Environment Variable
1. Go to Render Dashboard → Your Web Service → Environment
2. Update DATABASE_URL to include:
   - Full hostname ending in `.oregon-postgres.render.com`
   - Port number `:5432`

### 3. Wait for Database
- PostgreSQL service takes 1-2 minutes to become available
- Check your PostgreSQL service status shows "Available"

### 4. Redeploy
- Save environment variables
- Go to Deployments tab → "Manual Deploy" → "Deploy latest commit"

### 5. Check Logs
- Monitor deployment logs for connection retries
- Should see: "✅ Database connected successfully"

## Your Current DATABASE_URL
Update this in Render environment variables:
```
postgresql://crownsecurity_user:qQiOjO9MOKdZnoTsOiqpjI6EC5BvrTqk@dpg-d2qokl75r7bs73b1181g-a.oregon-postgres.render.com:5432/crownsecurity
```

## Alternative: Manual Migration
If connection still fails, run migrations manually:

1. Go to PostgreSQL service → Connect → External Connection
2. Copy the connection command
3. Use it to run: `npx sequelize-cli db:migrate --url "your_connection_string"`
