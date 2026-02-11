# Buku Masjid - Production Deployment Makefile
# Usage: make [target]

# Variables
DOCKER_COMPOSE_FILE = docker-compose.yml
DOCKER_COMPOSE_LOCAL_FILE = docker-compose-local.yml
PROJECT_NAME = buku-masjid
BACKUP_DIR = ./backups
LOG_DIR = ./logs

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

.PHONY: help install build run stop restart logs clean backup restore migrate seed check-env health status

# Default target
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "$(BLUE)Buku Masjid - Production Deployment Commands$(NC)"
	@echo "=============================================="
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Environment and Setup Commands
check-env: ## Check if required environment variables are set
	@echo "$(BLUE)Checking environment variables...$(NC)"
	@if [ ! -f .env ]; then echo "$(RED)Error: .env file not found!$(NC)"; exit 1; fi
	@if [ -z "$$(grep -v '^#' .env | grep -v '^$$' | grep 'DB_PASSWORD')" ]; then echo "$(RED)Error: DB_PASSWORD not set in .env$(NC)"; exit 1; fi
	@if [ -z "$$(grep -v '^#' .env | grep -v '^$$' | grep 'APP_KEY')" ]; then echo "$(RED)Error: APP_KEY not set in .env$(NC)"; exit 1; fi
	@echo "$(GREEN)Environment check passed!$(NC)"

install: check-env ## Install and setup the application
	@echo "$(BLUE)Installing Buku Masjid...$(NC)"
	@mkdir -p $(BACKUP_DIR) $(LOG_DIR)
	@docker-compose -f $(DOCKER_COMPOSE_FILE) pull
	@$(MAKE) build
	@$(MAKE) migrate
	@$(MAKE) seed
	@echo "$(GREEN)Installation completed!$(NC)"

# Build Commands
build: ## Build all Docker images
	@echo "$(BLUE)Building Docker images...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) build --no-cache
	@echo "$(GREEN)Build completed!$(NC)"

build-local: ## Build local development images
	@echo "$(BLUE)Building local development images...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_LOCAL_FILE) build --no-cache
	@echo "$(GREEN)Local build completed!$(NC)"

# Runtime Commands
run: check-env ## Start all services in production mode
	@echo "$(BLUE)Starting production services...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) up -d
	@echo "$(GREEN)Services started successfully!$(NC)"
	@$(MAKE) health

run-local: ## Start all services in local development mode
	@echo "$(BLUE)Starting local development services...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_LOCAL_FILE) up -d
	@echo "$(GREEN)Local services started successfully!$(NC)"

run-app: check-env ## Start only the application server
	@echo "$(BLUE)Starting application server...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) up -d server
	@echo "$(GREEN)Application server started!$(NC)"

run-db: check-env ## Start only the database
	@echo "$(BLUE)Starting database...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) up -d mysql
	@echo "$(GREEN)Database started!$(NC)"

run-redis: check-env ## Start only Redis cache
	@echo "$(BLUE)Starting Redis cache...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) up -d redis
	@echo "$(GREEN)Redis started!$(NC)"

stop: ## Stop all services
	@echo "$(YELLOW)Stopping all services...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) down
	@echo "$(GREEN)Services stopped!$(NC)"

stop-local: ## Stop local development services
	@echo "$(YELLOW)Stopping local services...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_LOCAL_FILE) down
	@echo "$(GREEN)Local services stopped!$(NC)"

restart: ## Restart all services
	@echo "$(BLUE)Restarting services...$(NC)"
	@$(MAKE) stop
	@$(MAKE) run
	@echo "$(GREEN)Services restarted!$(NC)"

restart-app: ## Restart only the application server
	@echo "$(BLUE)Restarting application server...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) restart server
	@echo "$(GREEN)Application server restarted!$(NC)"

restart-db: ## Restart only the database
	@echo "$(BLUE)Restarting database...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) restart mysql
	@echo "$(GREEN)Database restarted!$(NC)"

# Application Management
migrate: ## Run database migrations
	@echo "$(BLUE)Running database migrations...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec server php artisan migrate --force
	@echo "$(GREEN)Migrations completed!$(NC)"

seed: ## Seed the database with initial data
	@echo "$(BLUE)Seeding database...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec server php artisan db:seed --force
	@echo "$(GREEN)Database seeded!$(NC)"

optimize: ## Optimize Laravel application for production
	@echo "$(BLUE)Optimizing application...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec server php artisan config:cache
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec server php artisan route:cache
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec server php artisan view:cache
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec server php artisan event:cache
	@echo "$(GREEN)Application optimized!$(NC)"

clear-cache: ## Clear all Laravel caches
	@echo "$(BLUE)Clearing application caches...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec server php artisan cache:clear
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec server php artisan config:clear
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec server php artisan route:clear
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec server php artisan view:clear
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec server php artisan event:clear
	@echo "$(GREEN)Caches cleared!$(NC)"

# Monitoring and Logs
logs: ## Show logs from all services
	@echo "$(BLUE)Showing logs...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) logs -f

logs-app: ## Show application logs only
	@echo "$(BLUE)Showing application logs...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) logs -f server

logs-db: ## Show database logs only
	@echo "$(BLUE)Showing database logs...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) logs -f mysql

logs-redis: ## Show Redis logs only
	@echo "$(BLUE)Showing Redis logs...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) logs -f redis

status: ## Show status of all containers
	@echo "$(BLUE)Container Status:$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) ps

health: ## Check health of all services
	@echo "$(BLUE)Health Check:$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) ps
	@echo ""
	@echo "$(BLUE)Testing application endpoint...$(NC)"
	@if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then \
		echo "$(GREEN)✓ Application is responding$(NC)"; \
	else \
		echo "$(RED)✗ Application is not responding$(NC)"; \
		echo "$(YELLOW)Checking server logs:$(NC)"; \
		docker-compose -f $(DOCKER_COMPOSE_FILE) logs --tail=20 server; \
	fi

# Backup and Restore
backup: ## Create database backup
	@echo "$(BLUE)Creating database backup...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec mysql mysqldump -u root -p$${MYSQL_ROOT_PASSWORD} --all-databases > $(BACKUP_DIR)/backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)Backup created in $(BACKUP_DIR)/$(NC)"

restore: ## Restore database from backup (usage: make restore BACKUP_FILE=backup_file.sql)
	@echo "$(BLUE)Restoring database...$(NC)"
	@if [ -z "$(BACKUP_FILE)" ]; then echo "$(RED)Error: Please specify BACKUP_FILE=filename$(NC)"; exit 1; fi
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec -T mysql mysql -u root -p$${MYSQL_ROOT_PASSWORD} < $(BACKUP_DIR)/$(BACKUP_FILE)
	@echo "$(GREEN)Database restored from $(BACKUP_FILE)!$(NC)"

# Maintenance Commands
clean: ## Clean up Docker images and volumes
	@echo "$(YELLOW)Cleaning up Docker resources...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) down -v
	@docker system prune -f
	@docker volume prune -f
	@echo "$(GREEN)Cleanup completed!$(NC)"

update: ## Update application to latest version
	@echo "$(BLUE)Updating application...$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) pull
	@$(MAKE) stop
	@$(MAKE) build
	@$(MAKE) run
	@$(MAKE) migrate
	@$(MAKE) optimize
	@echo "$(GREEN)Update completed!$(NC)"

# Troubleshooting Commands
troubleshoot: ## Comprehensive troubleshooting for startup issues
	@echo "$(BLUE)System Resources:$(NC)"
	@echo "Memory:" && free -h
	@echo "Disk:" && df -h
	@echo ""
	@echo "$(BLUE)Docker Resources:$(NC)"
	@docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
	@echo ""
	@echo "$(BLUE)MySQL Restart Issues:$(NC)"
	@docker-compose logs mysql | grep -E "(ERROR|FATAL|restart|exit|died)" || echo "No critical MySQL errors found"
	@echo ""
	@echo "$(BLUE)Manual MySQL Test:$(NC)"
	@docker run --rm mysql:8.0 --version

fix-mysql: ## Stop everything and restart MySQL with minimal config
	@echo "$(YELLOW)Stopping all services...$(NC)"
	@docker-compose down -v
	@echo "$(BLUE)Starting MySQL alone with minimal config...$(NC)"
	@docker-compose up -d mysql
	@sleep 15
	@echo "$(BLUE)MySQL Status:$(NC)"
	@docker-compose ps mysql
	@docker-compose logs mysql
debug: ## Debug application issues
	@echo "$(BLUE)Container Status:$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) ps
	@echo ""
	@echo "$(BLUE)Server Container Logs (last 30 lines):$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) logs --tail=30 server
	@echo ""
	@echo "$(BLUE)Laravel Error Logs:$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec server tail -20 /var/www/html/storage/logs/laravel.log 2>/dev/null || echo "$(YELLOW)No Laravel logs found$(NC)"
	@echo ""
	@echo "$(BLUE)MySQL Container Logs (last 15 lines):$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) logs --tail=15 mysql
	@echo ""
	@echo "$(BLUE)Network Test:$(NC)"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec server curl -v http://localhost:8080 || echo "$(RED)Internal curl failed$(NC)"

# Development Commands
shell: ## Access application container shell
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec server bash

shell-db: ## Access database container shell
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec mysql bash

mysql-cli: ## Access MySQL CLI
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec mysql mysql -u root -p

redis-cli: ## Access Redis CLI
	@docker-compose -f $(DOCKER_COMPOSE_FILE) exec redis redis-cli

# Production Deployment
deploy: check-env ## Full production deployment
	@echo "$(BLUE)Starting production deployment...$(NC)"
	@$(MAKE) build
	@$(MAKE) run
	@sleep 30
	@$(MAKE) migrate
	@$(MAKE) optimize
	@$(MAKE) health
	@echo "$(GREEN)Production deployment completed successfully!$(NC)"

# Quick Commands
quick-start: ## Quick start for development (local)
	@$(MAKE) run-local

quick-stop: ## Quick stop for development (local) 
	@$(MAKE) stop-local