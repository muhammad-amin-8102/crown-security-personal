# Non-Docker Full-Stack Deployment Guide
# Deploy Flutter Web + Node.js API without Docker

## Deployment Architecture (Non-Docker)
```
Server Setup:
├── Node.js Runtime (v18+)
├── PostgreSQL Database (v15+)
├── Flutter SDK (for building web)
├── Process Manager (PM2)
└── Web Server (Nginx - optional)
```

## Prerequisites

### 1. Server Requirements
- Ubuntu 20.04+ / CentOS 8+ / Windows Server
- Node.js 18+ 
- PostgreSQL 15+
- Git
- SSL Certificate (Let's Encrypt recommended)

### 2. Install Dependencies
```bash
# Node.js (Ubuntu/Debian)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# PostgreSQL
sudo apt-get install postgresql postgresql-contrib

# PM2 Process Manager
npm install -g pm2

# Flutter (for build)
sudo snap install flutter --classic
```

## Deployment Steps

### 1. Database Setup
```bash
# Create database and user
sudo -u postgres psql
CREATE DATABASE crown_security;
CREATE USER app_user WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE crown_security TO app_user;
\q
```

### 2. Application Setup
```bash
# Clone repository
git clone https://github.com/muhammad-amin-8102/crown-security-personal.git
cd crown-security-personal

# Build Flutter Web
cd app/crown_security
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=/api/v1
cd ../..

# Copy Flutter build to backend
cp -r app/crown_security/build/web backend/public/admin

# Install backend dependencies
cd backend
npm install --production

# Run database migrations
npm run migrate

# Seed initial data (optional)
npm run seed
```

### 3. Environment Configuration
```bash
# Create production environment file
cat > .env.production << EOL
NODE_ENV=production
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=crown_security
DB_USER=app_user
DB_PASS=your_secure_password
JWT_ACCESS_SECRET=your_super_secure_jwt_access_secret_production
JWT_REFRESH_SECRET=your_super_secure_jwt_refresh_secret_production
JWT_ACCESS_TTL=2592000
JWT_REFRESH_TTL=2592000
FRONTEND_URL=https://yourdomain.com
APP_NAME=Crown Security
APP_VERSION=1.0.0
EOL
```

### 4. Process Management with PM2
```bash
# Create PM2 ecosystem file
cat > ecosystem.config.js << EOL
module.exports = {
  apps: [{
    name: 'crown-security',
    script: 'src/server.js',
    cwd: './backend',
    env_file: '.env.production',
    instances: 'max',
    exec_mode: 'cluster',
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    log_file: '/var/log/crown-security/combined.log',
    out_file: '/var/log/crown-security/out.log',
    error_file: '/var/log/crown-security/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm Z'
  }]
};
EOL

# Create log directory
sudo mkdir -p /var/log/crown-security
sudo chown $USER:$USER /var/log/crown-security

# Start application
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### 5. Nginx Configuration (Optional but Recommended)
```bash
# Install Nginx
sudo apt-get install nginx

# Create Nginx configuration
sudo cat > /etc/nginx/sites-available/crown-security << EOL
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;
    
    # SSL Configuration
    ssl_certificate /path/to/ssl/certificate.crt;
    ssl_certificate_key /path/to/ssl/private.key;
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    
    # Admin Portal (Flutter Web)
    location /admin {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # API Routes
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:3000;
        access_log off;
    }
    
    # Root redirect to admin
    location = / {
        return 302 /admin/;
    }
}
EOL

# Enable site
sudo ln -s /etc/nginx/sites-available/crown-security /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## SSL Certificate with Let's Encrypt
```bash
# Install Certbot
sudo apt-get install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Auto-renewal (crontab)
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
```

## Monitoring and Maintenance

### 1. Health Checks
```bash
# Application health
curl https://yourdomain.com/health

# PM2 status
pm2 status
pm2 logs crown-security

# Database status
sudo -u postgres psql -c "SELECT version();"
```

### 2. Updates and Deployments
```bash
# Pull latest changes
git pull origin main

# Rebuild Flutter web (if frontend changes)
cd app/crown_security
flutter build web --release --dart-define=API_BASE_URL=/api/v1
cp -r build/web ../../backend/public/admin
cd ../../backend

# Install new dependencies (if any)
npm install --production

# Run migrations (if any)
npm run migrate

# Restart application
pm2 restart crown-security

# Reload Nginx (if config changed)
sudo systemctl reload nginx
```

### 3. Backup Strategy
```bash
# Database backup
pg_dump -h localhost -U app_user crown_security > backup_$(date +%Y%m%d_%H%M%S).sql

# Application files backup
tar -czf app_backup_$(date +%Y%m%d_%H%M%S).tar.gz backend/

# Automated backup (crontab)
echo "0 2 * * * /path/to/backup_script.sh" | crontab -
```

## Troubleshooting

### Common Issues
1. **Port already in use**: `sudo netstat -tulpn | grep :3000`
2. **Database connection**: Check PostgreSQL status and credentials
3. **Permission denied**: Ensure proper file ownership and permissions
4. **SSL issues**: Verify certificate paths and renewal
5. **Memory issues**: Monitor with `pm2 monit` and adjust max_memory_restart

### Logs Location
- Application logs: `/var/log/crown-security/`
- Nginx logs: `/var/log/nginx/`
- PostgreSQL logs: `/var/log/postgresql/`
- PM2 logs: `~/.pm2/logs/`

## Security Checklist
- [ ] Firewall configured (only ports 80, 443, 22)
- [ ] Database access restricted to localhost
- [ ] Strong JWT secrets in production
- [ ] SSL certificate installed and auto-renewal enabled
- [ ] Regular security updates applied
- [ ] Application running as non-root user
- [ ] File permissions properly set (644 for files, 755 for directories)

## Performance Optimization
- [ ] PM2 cluster mode enabled
- [ ] Nginx gzip compression enabled
- [ ] Database connection pooling configured
- [ ] Static files served by Nginx
- [ ] Application logs rotated
- [ ] Database query optimization
- [ ] CDN for static assets (optional)
