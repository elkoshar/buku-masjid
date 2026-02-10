#!/bin/bash

# Buku Masjid - Production Deployment Script
# This script automates the deployment process

set -e  # Exit on any error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Buku Masjid"
BACKUP_RETENTION_DAYS=30

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed or not in PATH"
        exit 1
    fi
    
    log_success "Dependencies check passed"
}

check_environment() {
    log_info "Checking environment configuration..."
    
    if [[ ! -f .env ]]; then
        log_error ".env file not found"
        if [[ -f .env.production ]]; then
            log_info "Found .env.production template. Please copy it to .env and configure:"
            log_info "cp .env.production .env"
        fi
        exit 1
    fi
    
    # Check required environment variables
    required_vars=("DB_PASSWORD" "DB_ROOT_PASSWORD" "APP_KEY")
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}=" .env || grep -q "^${var}=$" .env; then
            log_error "Required environment variable ${var} is not set in .env"
            exit 1
        fi
    done
    
    log_success "Environment configuration check passed"
}

create_backup() {
    log_info "Creating backup before deployment..."
    
    # Create backup directory if it doesn't exist
    mkdir -p ./backups
    
    # Check if database is running
    if docker-compose ps mysql | grep -q "Up"; then
        BACKUP_FILE="./backups/pre_deploy_backup_$(date +%Y%m%d_%H%M%S).sql"
        
        # Get database password from .env
        DB_ROOT_PASSWORD=$(grep "^DB_ROOT_PASSWORD=" .env | cut -d '=' -f2)
        
        if docker-compose exec -T mysql mysqldump -u root -p"${DB_ROOT_PASSWORD}" --all-databases > "${BACKUP_FILE}"; then
            log_success "Backup created: ${BACKUP_FILE}"
        else
            log_warning "Backup creation failed, but continuing with deployment"
        fi
    else
        log_info "Database not running, skipping backup"
    fi
}

cleanup_old_backups() {
    log_info "Cleaning up old backups (older than ${BACKUP_RETENTION_DAYS} days)..."
    
    if [[ -d ./backups ]]; then
        find ./backups -name "*.sql" -mtime +${BACKUP_RETENTION_DAYS} -delete
        log_success "Old backups cleaned up"
    fi
}

deploy() {
    log_info "Starting deployment of ${APP_NAME}..."
    
    # Pull latest images
    log_info "Pulling latest Docker images..."
    docker-compose pull
    
    # Build images
    log_info "Building application images..."
    docker-compose build --no-cache
    
    # Stop existing services
    log_info "Stopping existing services..."
    docker-compose down
    
    # Start services
    log_info "Starting services..."
    docker-compose up -d
    
    # Wait for services to be healthy
    log_info "Waiting for services to be healthy..."
    sleep 30
    
    # Check if services are running
    if ! docker-compose ps | grep -q "Up"; then
        log_error "Some services failed to start"
        docker-compose logs
        exit 1
    fi
    
    # Run migrations
    log_info "Running database migrations..."
    docker-compose exec server php artisan migrate --force
    
    # Optimize application
    log_info "Optimizing application for production..."
    docker-compose exec server php artisan config:cache
    docker-compose exec server php artisan route:cache
    docker-compose exec server php artisan view:cache
    
    # Test application
    log_info "Testing application..."
    sleep 10
    
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
        log_success "Application is responding correctly"
    else
        log_error "Application is not responding"
        docker-compose logs server
        exit 1
    fi
    
    log_success "Deployment completed successfully!"
}

rollback() {
    log_warning "Rolling back to previous state..."
    
    # Stop current services
    docker-compose down
    
    # Restore from backup if available
    LATEST_BACKUP=$(ls -t ./backups/pre_deploy_backup_*.sql 2>/dev/null | head -n1)
    
    if [[ -n "${LATEST_BACKUP}" ]]; then
        log_info "Restoring from backup: ${LATEST_BACKUP}"
        
        # Start database
        docker-compose up -d mysql
        sleep 20
        
        # Restore backup
        DB_ROOT_PASSWORD=$(grep "^DB_ROOT_PASSWORD=" .env | cut -d '=' -f2)
        docker-compose exec -T mysql mysql -u root -p"${DB_ROOT_PASSWORD}" < "${LATEST_BACKUP}"
        
        log_success "Rollback completed"
    else
        log_warning "No backup found for rollback"
    fi
}

show_status() {
    log_info "Current deployment status:"
    docker-compose ps
    echo ""
    log_info "Application health check:"
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
        log_success "✓ Application is healthy"
    else
        log_error "✗ Application is not responding"
    fi
}

# Main script
case "${1:-deploy}" in
    "deploy")
        check_dependencies
        check_environment
        create_backup
        deploy
        cleanup_old_backups
        show_status
        ;;
    "rollback")
        rollback
        ;;
    "status")
        show_status
        ;;
    "backup")
        create_backup
        ;;
    *)
        echo "Usage: $0 {deploy|rollback|status|backup}"
        echo ""
        echo "  deploy   - Full deployment (default)"
        echo "  rollback - Rollback to previous state"
        echo "  status   - Show current status"
        echo "  backup   - Create backup only"
        exit 1
        ;;
esac