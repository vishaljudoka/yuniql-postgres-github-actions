#!/bin/bash
# =============================================================================
# Run Yuniql Migrations Locally (via Docker)
# =============================================================================
# Usage: ./scripts/run-local.sh
# Requires: Docker, .env file with database credentials
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SCRIPT_DIR/.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Yuniql Local Migration Runner"
echo "=========================================="

# Check for .env file
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: .env file not found at $ENV_FILE${NC}"
    echo "Copy .env.example to .env and update with your credentials:"
    echo "  cp scripts/.env.example scripts/.env"
    exit 1
fi

# Load environment variables
source "$ENV_FILE"

# Validate required variables
if [ -z "$DB_HOST" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    echo -e "${RED}Error: Missing required environment variables${NC}"
    echo "Required: DB_HOST, DB_NAME, DB_USER, DB_PASSWORD"
    exit 1
fi

# Set defaults
DB_PORT="${DB_PORT:-5432}"
YUNIQL_VERSION="${YUNIQL_VERSION:-1.3.15}"
MIGRATIONS_PATH="$PROJECT_ROOT/db/migrations"

echo "Database: $DB_NAME @ $DB_HOST:$DB_PORT"
echo "Migrations: $MIGRATIONS_PATH"
echo "Yuniql Version: $YUNIQL_VERSION"
echo "------------------------------------------"

# Build connection string
CONNECTION_STRING="Host=$DB_HOST;Port=$DB_PORT;Database=$DB_NAME;Username=$DB_USER;Password=$DB_PASSWORD"

# Add SSL for remote databases (not localhost)
if [ "$DB_HOST" != "localhost" ] && [ "$DB_HOST" != "127.0.0.1" ]; then
    CONNECTION_STRING="$CONNECTION_STRING;SSL Mode=Require;Trust Server Certificate=true"
    echo -e "${YELLOW}Note: SSL enabled for remote connection${NC}"
fi

echo ""
echo "Running migrations..."
echo "------------------------------------------"

# Run Yuniql via Docker
docker run --rm \
    -v "$MIGRATIONS_PATH:/db" \
    mcr.microsoft.com/dotnet/sdk:8.0 \
    bash -c "
        dotnet tool install -g yuniql.cli --version $YUNIQL_VERSION > /dev/null 2>&1
        export PATH=\"\$PATH:/root/.dotnet/tools\"
        yuniql run \
            --platform postgresql \
            --connection-string '$CONNECTION_STRING' \
            --path /db \
            --auto-create-db false \
            --debug
    "

echo ""
echo "------------------------------------------"
echo -e "${GREEN}Migrations completed successfully!${NC}"
