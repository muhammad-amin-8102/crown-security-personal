# 🚨 Fix Database Connection Error on Render

## 🔍 Current Issue Analysis
Based on your logs, the connection is being refused. This typically means:

1. **PostgreSQL service isn't ready yet** (most common)
2. **DATABASE_URL format is incorrect**
3. **Service connectivity issues**

## ✅ Step-by-Step Fix

### 1. Check PostgreSQL Service Status
1. Go to Render Dashboard → Your PostgreSQL service
2. **Status must show "Available"** (not "Building" or "Deploy in progress")
3. If not available, wait 2-3 minutes for it to finish starting

### 2. Verify DATABASE_URL Format
Your current format should be:
```
postgresql://crownsecurity_user:qQiOjO9MOKdZnoTsOiqpjI6EC5BvrTqk@dpg-d2qokl75r7bs73b1181g-a.oregon-postgres.render.com:5432/crownsecurity
```

**Check these components:**
- ✅ Starts with `postgresql://`
- ✅ Has username and password
- ✅ Hostname ends with `.oregon-postgres.render.com`
- ✅ Includes port `:5432`
- ✅ Database name at the end

### 3. Get Fresh DATABASE_URL from Render
1. Go to PostgreSQL service → "Connect" tab
2. Copy the **External Connection** URL
3. It should look like:
   ```
   postgresql://username:password@dpg-xxxxx-a.oregon-postgres.render.com:5432/database_name
   ```

### 4. Update Environment Variables
1. Go to Web Service → Environment tab
2. Update `DATABASE_URL` with the fresh URL from step 3
3. Click "Save Changes"

### 5. Force Redeploy
1. Go to Deployments tab
2. Click "Manual Deploy" → "Deploy latest commit"
3. Watch logs for connection attempts

## 🔄 Alternative: Create New Database
If the issue persists:

1. **Create fresh PostgreSQL service:**
   - New → PostgreSQL
   - Name: `crown-security-db-new`
   - Plan: Free

2. **Get new connection details:**
   - Wait for "Available" status
   - Copy External Connection URL

3. **Update web service:**
   - Environment → DATABASE_URL = new URL
   - Redeploy

## 🐛 Debug Commands
If you have access to Render shell:

```bash
# Test connection manually
psql "postgresql://username:password@hostname:5432/database"

# Check if port 5432 is accessible
nc -zv hostname 5432
```

## 📞 Common Error Patterns

| Error | Cause | Solution |
|-------|-------|----------|
| `ECONNREFUSED` | DB not ready or wrong URL | Wait or check URL format |
| `ENOTFOUND` | Hostname incorrect | Verify full hostname with .render.com |
| `ECONNRESET` | Connection dropped | Check service status |
| `password authentication failed` | Wrong credentials | Get fresh URL from dashboard |

## ⏰ Expected Timeline
- **New PostgreSQL service**: 1-2 minutes to become available
- **Connection retry**: 5 attempts over 25 seconds
- **Service restart**: 30-60 seconds

Your app will automatically retry connections, so once the database is ready, it should connect successfully.
