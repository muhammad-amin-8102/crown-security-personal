#!/bin/bash

# Crown Security Docker Health Check
echo "🏥 Crown Security Docker Health Check"
echo "===================================="

# Check if Docker is running
if ! docker --version &> /dev/null; then
    echo "❌ Docker is not installed or not running"
    exit 1
fi

echo "✅ Docker is available"

# Check if containers are running
if docker-compose ps | grep -q "Up"; then
    echo "✅ Docker containers are running"
    
    # Test API health endpoint
    echo "🔍 Testing API health endpoint..."
    if curl -f http://localhost:3000/health &> /dev/null; then
        echo "✅ API health check passed"
    else
        echo "❌ API health check failed"
        echo "📋 Container logs:"
        docker-compose logs --tail=10 backend
    fi
    
    # Test database connection
    echo "🔍 Testing database connection..."
    if docker-compose exec -T backend npm run test-db &> /dev/null; then
        echo "✅ Database connection successful"
    else
        echo "❌ Database connection failed"
    fi
    
else
    echo "❌ No Docker containers are running"
    echo "💡 Run: docker-compose up -d"
fi

echo ""
echo "📊 Container Status:"
docker-compose ps
