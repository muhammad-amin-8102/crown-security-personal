#!/bin/bash

echo "🚀 Deploying Crown Security with fresh database reset..."

# Add all changes
echo "📦 Adding changes to git..."
git add .

# Commit changes
echo "💾 Committing changes..."
git commit -m "Added site selector dropdown for clients and production database reset functionality

- Created SiteSelector widget for client site selection
- Updated dashboard to show site dropdown and selected site name  
- Added production-safe database reset script that clears data without dropping tables
- Updated deployment process to reset database on each deploy to prevent duplicate data
- Enhanced error handling and user experience for site selection"

# Push to trigger Render deployment
echo "🌐 Pushing to repository (this will trigger Render deployment)..."
git push origin main

echo "✅ Deployment initiated! The production database will be reset and reseeded automatically."
echo "🔍 Check Render logs to monitor the deployment progress."
