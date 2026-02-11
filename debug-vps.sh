#!/bin/bash

echo "=== Docker Compose Status ==="
docker-compose ps

echo -e "\n=== Container Logs (Server) ==="
docker-compose logs server --tail=50

echo -e "\n=== Container Logs (MySQL) ==="
docker-compose logs mysql --tail=20

echo -e "\n=== Test Container Access ==="
docker-compose exec server curl -v http://localhost:8080 || echo "Direct curl failed"

echo -e "\n=== Check if Laravel is running ==="
docker-compose exec server ps aux | grep php || echo "No PHP process found"

echo -e "\n=== Check Web Server ==="
docker-compose exec server ps aux | grep nginx || echo "No Nginx process found"

echo -e "\n=== Environment Variables ==="
docker-compose exec server env | grep -E "(APP_|DB_)" || echo "Env check failed"