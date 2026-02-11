#!/bin/bash

echo "=== Step 1: Pull latest changes ==="
git pull origin master

echo -e "\n=== Step 2: Check if .env exists ==="
if [ -f .env ]; then
    echo "✓ .env file exists"
else
    echo "✗ .env file missing! Creating from template..."
    cp .env.production .env
    echo "Please edit .env file with your database passwords"
fi

echo -e "\n=== Step 3: Start MySQL first ==="
docker-compose up -d mysql

echo -e "\n=== Step 4: Wait and check MySQL logs ==="
sleep 10
docker-compose logs mysql

echo -e "\n=== Step 5: Check MySQL status ==="
docker-compose ps mysql

echo -e "\n=== Step 6: If MySQL is healthy, start server ==="
echo "Run: docker-compose up -d server"
echo "Then: docker-compose logs server"