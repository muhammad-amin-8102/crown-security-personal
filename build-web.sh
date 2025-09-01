#!/bin/bash

# Flutter Web Build Script for Crown Security Admin Portal
echo "🌐 Building Crown Security Admin Portal for Web"
echo "==============================================="

# Navigate to Flutter project
cd "$(dirname "$0")/app/crown_security"

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Build for web
echo "🏗️ Building Flutter web app..."
flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL:-http://localhost:3000} \
    --base-href=/admin/ \
    --no-wasm-dry-run
    --output build/web

# Copy to backend public directory
echo "📁 Copying build to backend..."
BACKEND_PUBLIC="../../../backend/public/admin"
mkdir -p "$BACKEND_PUBLIC"
cp -r build/web/* "$BACKEND_PUBLIC/"

echo "✅ Web build completed successfully!"
echo ""
echo "🌐 Admin portal will be available at:"
echo "   Local: http://localhost:3000/admin"
echo "   Production: https://your-domain.com/admin"
echo ""
echo "📂 Files copied to: backend/public/admin/"
