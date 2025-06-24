#!/bin/bash

# === Configuration ===
CONTAINER_NAME=joomla-mysql
MYSQL_ROOT_PASSWORD=my-secret-pw
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
DB_BACKUP_FILE=$BACKUP_DIR/my-joomla-backup_$TIMESTAMP.sql.gz
VOLUME_BACKUP_FILE=$BACKUP_DIR/joomla_html_$TIMESTAMP.tar.gz

# === Ensure backup directory exists ===
mkdir -p "$BACKUP_DIR"

echo "📦 Starting MySQL database backup..."

# === Backup MySQL Database ===
docker exec "$CONTAINER_NAME" sh -c \
  "exec mysqldump --all-databases -uroot -p$MYSQL_ROOT_PASSWORD" | gzip > "$DB_BACKUP_FILE"

if [ $? -eq 0 ]; then
  echo "✅ Database backup saved to: $DB_BACKUP_FILE"
else
  echo "❌ Database backup failed."
  exit 1
fi

echo "📁 Backing up Joomla HTML volume..."

# === Backup Joomla Volume (site files) ===
docker run --rm \
  -v joomla-html:/from \
  -v "$BACKUP_DIR":/to \
  alpine sh -c "cd /from && tar czf /to/joomla_html_$TIMESTAMP.tar.gz ."

if [ $? -eq 0 ]; then
  echo "✅ Joomla volume backup saved to: $VOLUME_BACKUP_FILE"
else
  echo "❌ Joomla volume backup failed."
  exit 1
fi

echo "🎉 All backups completed successfully."

