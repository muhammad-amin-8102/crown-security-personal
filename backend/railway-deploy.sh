#!/bin/bash

# Railway.com Deployment Script
# This script runs automatically on Railway after successful build

echo "🚀 Starting Crown Security API deployment..."

# Run database migrations
echo "📊 Running database migrations..."
npm run db:migrate

# Run database seeders (only if needed)
echo "🌱 Running database seeders..."
npm run db:seed

echo "✅ Deployment completed successfully!"
echo "🌐 API is ready to serve requests"
