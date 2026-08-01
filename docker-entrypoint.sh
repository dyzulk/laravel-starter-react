#!/bin/sh
set -e

echo "Starting deployment checks..."

# Ensure database directory exists
mkdir -p /app/database

# Ensure SQLite file exists
if [ ! -f /app/database/database.sqlite ]; then
    echo "Creating SQLite database file..."
    touch /app/database/database.sqlite
fi

# Set directory permissions for SQLite and Laravel directories
echo "Configuring permissions..."
chmod -R 777 /app/database
chmod -R 777 /app/storage
chmod -R 777 /app/bootstrap/cache

# Run database migrations
echo "Running database migrations..."
php artisan migrate --force

# Pass execution to the original container entrypoint
echo "Starting FrankenPHP..."
exec docker-php-entrypoint "$@"
