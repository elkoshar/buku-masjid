# ================
# Base Stage
# ================
FROM serversideup/php:8.1-fpm-nginx as base
ENV AUTORUN_ENABLED=false
ENV SSL_MODE=off

# ================
# Production Stage
# ================
FROM base as production

ENV APP_ENV=production
ENV APP_DEBUG=false

# Required Modules
USER root:root
RUN apt-get update && \
    apt-get install -y libpng-dev libicu-dev && \
    docker-php-ext-configure intl && \
    docker-php-ext-install pdo_mysql gd intl && \
    docker-php-ext-enable intl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Copy contents.
# - To ignore files or folders, use .dockerignore
COPY --chown=www-data:www-data . .

# Copy and set up entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN composer install --optimize-autoloader --no-dev --no-interaction --no-progress --ansi

# Setup environment file
RUN if [ ! -f .env ]; then \
        cp .env.example .env && \
        sed -i 's/DB_HOST=127.0.0.1/DB_HOST=mysql/' .env; \
    fi

# artisan commands
RUN php ./artisan key:generate && \
    php ./artisan passport:keys && \
    php ./artisan view:cache && \
    php ./artisan route:cache && \
    php ./artisan config:cache && \
    php ./artisan storage:link

# Fix permissions for Laravel directories
RUN chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache
