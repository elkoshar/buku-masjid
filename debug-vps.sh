#!/bin/bash

echo "=== Docker Compose Status ==="
docker-compose ps

echo -e "\n=== Container Logs (Server) ==="
docker-compose logs server 2>/dev/null || echo "Server container not running"

echo -e "\n=== Container Logs (MySQL) ==="
docker-compose logs mysql 2>/dev/null || echo "MySQL container not running"

echo -e "\n=== MySQL Container Details ==="
docker inspect $(docker-compose ps -q mysql) 2>/dev/null | grep -A 5 -B 5 "RestartCount\|Status\|Error" || echo "MySQL container details not available"

echo -e "\n=== Check Environment File ==="
if [ -f .env ]; then
    echo "✓ .env file exists"
    echo "Environment variables:"
    grep -E "DB_|MYSQL_" .env | sed 's/=.*/=***/' || echo "No DB variables found"
else
    echo "✗ .env file missing!"
fi

echo -e "\n=== Disk Space ==="
df -h

echo -e "\n=== Test Container Access ==="
docker-compose exec server curl -v http://localhost:8080 2>/dev/null || echo "Server container not accessible"

echo -e "\n=== Check if Laravel is running ==="
docker-compose exec server ps aux 2>/dev/null | grep php || echo "No PHP process found"

echo -e "\n=== Check Web Server ==="
docker-compose exec server ps aux 2>/dev/null | grep nginx || echo "No Nginx process found"

echo -e "\n=== Environment Variables ==="
docker-compose exec server env 2>/dev/null | grep -E "(APP_|DB_)" || echo "Env check failed - container not running"