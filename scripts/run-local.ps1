# =============================================================================
# Run Yuniql Migrations Locally (via Docker) - Windows PowerShell
# =============================================================================
# Usage: .\scripts\run-local.ps1
# Requires: Docker Desktop, .env file with database credentials
# =============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$EnvFile = Join-Path $ScriptDir ".env"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Yuniql Local Migration Runner (Windows)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check for .env file
if (-not (Test-Path $EnvFile)) {
    Write-Host "Error: .env file not found at $EnvFile" -ForegroundColor Red
    Write-Host "Copy .env.example to .env and update with your credentials:"
    Write-Host "  Copy-Item scripts\.env.example scripts\.env"
    exit 1
}

# Load environment variables from .env
Get-Content $EnvFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Variable -Name $name -Value $value -Scope Script
    }
}

# Validate required variables
if (-not $DB_HOST -or -not $DB_NAME -or -not $DB_USER -or -not $DB_PASSWORD) {
    Write-Host "Error: Missing required environment variables" -ForegroundColor Red
    Write-Host "Required: DB_HOST, DB_NAME, DB_USER, DB_PASSWORD"
    exit 1
}

# Set defaults
if (-not $DB_PORT) { $DB_PORT = "5432" }
if (-not $YUNIQL_VERSION) { $YUNIQL_VERSION = "1.3.15" }

$MigrationsPath = Join-Path $ProjectRoot "db\migrations"

Write-Host "Database: $DB_NAME @ ${DB_HOST}:${DB_PORT}"
Write-Host "Migrations: $MigrationsPath"
Write-Host "Yuniql Version: $YUNIQL_VERSION"
Write-Host "------------------------------------------"

# Build connection string
$ConnectionString = "Host=$DB_HOST;Port=$DB_PORT;Database=$DB_NAME;Username=$DB_USER;Password=$DB_PASSWORD"

# Add SSL for remote databases
if ($DB_HOST -ne "localhost" -and $DB_HOST -ne "127.0.0.1") {
    $ConnectionString = "$ConnectionString;SSL Mode=Require;Trust Server Certificate=true"
    Write-Host "Note: SSL enabled for remote connection" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Running migrations..."
Write-Host "------------------------------------------"

# Convert Windows path to Docker-compatible path
$DockerPath = $MigrationsPath -replace '\\', '/' -replace '^([A-Za-z]):', '/$1'
$DockerPath = $DockerPath.ToLower()

# Run Yuniql via Docker
docker run --rm `
    -v "${MigrationsPath}:/db" `
    mcr.microsoft.com/dotnet/sdk:8.0 `
    bash -c "dotnet tool install -g yuniql.cli --version $YUNIQL_VERSION > /dev/null 2>&1 && export PATH=`"`$PATH:/root/.dotnet/tools`" && yuniql run --platform postgresql --connection-string '$ConnectionString' --path /db --auto-create-db false --debug"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "------------------------------------------"
    Write-Host "Migrations completed successfully!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "------------------------------------------"
    Write-Host "Migration failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
