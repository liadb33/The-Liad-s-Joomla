#!/bin/bash

echo "🧹 Cleaning up Joomla project environment..."

# === Stop and remove containers ===
docker rm -f joomla joomla-mysql 2>/dev/null

# === Remove volumes ===
docker volume rm joomla-html joomla-mysql-data 2>/dev/null

# === Remove network ===
docker network rm joomla-network 2>/dev/null

# === Remove images (optional - comment if you want to keep them) ===
# docker rmi joomla mysql:8 2>/dev/null

# === Delete backup files ===
rm -f ./backups/*.sql.gz
rm -f ./backups/*.tar.gz

echo "✅ Environment cleaned up. You are back to square one."
