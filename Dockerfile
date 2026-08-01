# ==========================================
# Stage 1: Build Frontend Assets
# ==========================================
FROM node:24-alpine AS frontend-builder
WORKDIR /app

# Enable corepack to use pnpm
RUN corepack enable

# Copy package files and install dependencies using pnpm
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install

# Copy assets and configuration
COPY resources ./resources
COPY vite.config.ts tsconfig.json postcss.config.js tailwind.config.js* ./
COPY public ./public

# Compile frontend assets using pnpm
RUN pnpm run build

# ==========================================
# Stage 2: Runtime Production Environment
# ==========================================
FROM dunglas/frankenphp:1-php8.4-alpine AS runtime
WORKDIR /app

# Install production PHP extensions for Laravel
RUN install-php-extensions \
    pdo_sqlite \
    sqlite3 \
    pcntl \
    opcache \
    intl \
    zip \
    gd \
    redis

# Copy Composer binary from official image
COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

# Copy application source code
COPY . .

# Copy built frontend assets from Stage 1
COPY --from=frontend-builder /app/public/build ./public/build

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs

# Configure FrankenPHP port and document root
ENV SERVER_NAME=:3000
ENV SERVER_ROOT=/app/public

# Copy entrypoint script and make it executable
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
