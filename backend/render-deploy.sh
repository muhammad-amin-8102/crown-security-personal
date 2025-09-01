#!/bin/bash

# Render.com Deployment Script
# This script runs automatically on Render when deploying

echo "Starting Render deployment for Crown Security API..."

# Install dependencies
echo "Installing dependencies..."
npm install

# Run database migrations
echo "Running database migrations..."
npm run db:migrate

# Seed database (optional - only for initial deployment)
# echo "Seeding database..."
# npm run db:seed

echo "Deployment completed successfully!"
echo "API should be available at your Render service URL"
