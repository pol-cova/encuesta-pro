#!/bin/bash

echo "🧹 Cleaning up Encuesta Production..."

# Check if docker-compose file exists
if [ ! -f "docker-compose.prod.yaml" ]; then
    echo "❌ docker-compose.prod.yaml not found. Nothing to clean."
    exit 1
fi

echo "⚠️  This will remove ALL containers, volumes, and images!"
echo "Are you sure? (y/N)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "🔄 Stopping and removing services..."
    docker-compose -f docker-compose.prod.yaml down -v
    
    echo "🗑️  Removing Docker images..."
    docker system prune -af
    
    echo "🗑️  Removing Docker volumes..."
    docker volume prune -f
    
    echo "✅ Cleanup complete!"
else
    echo "❌ Cleanup cancelled."
fi
