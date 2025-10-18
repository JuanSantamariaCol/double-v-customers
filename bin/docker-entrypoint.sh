#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails
rm -f /app/tmp/pids/server.pid

# Wait for database to be ready
echo "Waiting for database to be ready..."
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c '\q' 2>/dev/null; do
  echo "Postgres is unavailable - sleeping"
  sleep 1
done

echo "Database is ready!"

# Create database if it doesn't exist
bundle exec rails db:create 2>/dev/null || true

# Run database migrations
echo "Running database migrations..."
bundle exec rails db:migrate

# Execute the container's main process
exec "$@"
