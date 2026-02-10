# Buku Masjid - Production Deployment Guide

This guide provides everything you need to deploy Buku Masjid in a production environment using Docker.

## 🚀 Quick Start

```bash
# 1. Copy environment configuration
cp .env.production .env

# 2. Edit .env with your production values
nano .env

# 3. Deploy the application
make deploy
```

## 📋 Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Make utility
- Minimum 2GB RAM
- 10GB free disk space

## 🔧 Production Configuration

### Environment Variables

Edit `.env` file with your production settings:

```bash
# Required Settings
APP_URL=https://your-domain.com
DB_PASSWORD=your_secure_password
DB_ROOT_PASSWORD=your_secure_root_password
APP_KEY=base64:your_app_key_here
```

### SSL/TLS Configuration

For production, configure a reverse proxy (nginx/Apache) or use a load balancer to handle SSL termination.

## 📋 Available Make Commands

### Deployment Commands
```bash
make install        # Full installation setup
make deploy         # Complete production deployment
make build          # Build Docker images
make update         # Update to latest version
```

### Runtime Commands
```bash
make run            # Start all services
make run-app        # Start application server only
make run-db         # Start database only
make run-redis      # Start Redis cache only
make stop           # Stop all services
make restart        # Restart all services
```

### Database Commands
```bash
make migrate        # Run database migrations
make seed           # Seed database with initial data
make backup         # Create database backup
make restore BACKUP_FILE=filename.sql  # Restore from backup
```

### Monitoring Commands
```bash
make status         # Show container status
make health         # Check service health
make logs           # Show all logs
make logs-app       # Show application logs only
make logs-db        # Show database logs only
```

### Maintenance Commands
```bash
make optimize       # Optimize Laravel for production
make clear-cache    # Clear all caches
make clean          # Clean up Docker resources
```

### Development Commands
```bash
make shell          # Access application shell
make mysql-cli      # Access MySQL CLI
make redis-cli      # Access Redis CLI
```

## 🚀 Deployment Methods

### Method 1: Using Make (Recommended)
```bash
make deploy
```

### Method 2: Using Deployment Script
```bash
./deploy.sh deploy    # Full deployment
./deploy.sh status    # Check status
./deploy.sh backup    # Create backup
./deploy.sh rollback  # Rollback deployment
```

### Method 3: Manual Docker Compose
```bash
docker-compose up -d
docker-compose exec server php artisan migrate --force
docker-compose exec server php artisan config:cache
```

## 🔒 Security Considerations

1. **Environment Variables**: Never commit `.env` to version control
2. **Database Passwords**: Use strong, unique passwords
3. **Firewall**: Only expose necessary ports (80, 443, 22)
4. **Updates**: Regularly update Docker images and dependencies
5. **Backups**: Automated daily backups recommended
6. **SSL**: Always use HTTPS in production
7. **Access Control**: Limit SSH and database access

## 📊 Monitoring & Maintenance

### Health Checks
```bash
# Application health
curl -f http://localhost:8080/healthcheck

# Database health
make mysql-cli
> SELECT 1;

# Redis health  
make redis-cli
> PING
```

### Log Management
```bash
# Application logs
make logs-app

# Error logs
docker-compose exec server tail -f storage/logs/laravel.log

# Database logs
make logs-db
```

### Performance Monitoring
```bash
# Container resource usage
docker stats

# Service status
make status

# Application metrics
make health
```

## 🔄 Backup & Recovery

### Automatic Backups
Backups are automatically created:
- Before each deployment
- Old backups (30+ days) are automatically cleaned

### Manual Backup
```bash
make backup
```

### Restore from Backup
```bash
make restore BACKUP_FILE=backup_20241211_120000.sql
```

## 🐛 Troubleshooting

### Common Issues

1. **Port conflicts**
   ```bash
   # Change port in docker-compose.yml if 8080 is in use
   ports:
     - "8081:8080"  # Use different external port
   ```

2. **Permission errors**
   ```bash
   # Fix storage permissions
   docker-compose exec server chown -R www-data:www-data storage bootstrap/cache
   ```

3. **Database connection issues**
   ```bash
   # Check database status
   make logs-db
   make mysql-cli
   ```

4. **Memory issues**
   ```bash
   # Increase memory limits in docker-compose.yml
   deploy:
     resources:
       limits:
         memory: 1G
   ```

### Service Status Check
```bash
make health
```

### Logs for Debugging
```bash
# All service logs
make logs

# Specific service logs
make logs-app
make logs-db
make logs-redis
```

## 🔄 Updates & Maintenance

### Update Application
```bash
make update
```

### Clear Caches
```bash
make clear-cache
```

### Optimize Performance
```bash
make optimize
```

## 📞 Support

For issues and support:
1. Check logs: `make logs`
2. Review health status: `make health`
3. Check documentation
4. Create an issue in the repository

## 📄 Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Load Balancer │    │   Application   │    │     MySQL       │
│   (nginx/Apache)│────│   (Laravel)     │────│   Database      │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                       ┌─────────────────┐
                       │     Redis       │
                       │     Cache       │
                       │                 │
                       └─────────────────┘
```

The application runs with:
- **Application Server**: nginx + PHP 8.1 + Laravel
- **Database**: MySQL 8.0 with optimized configuration
- **Cache**: Redis for session and application caching
- **Storage**: Persistent volumes for data and logs