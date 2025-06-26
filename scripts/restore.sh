#!/bin/bash

# === Configuration ===
MYSQL_CONTAINER=joomla-mysql
DB_NAME=joomla
DB_USER=root
DB_PASS=my-secret-pw
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/backups"

# === Input files ===
DB_BACKUP_FILE=$1
HTML_BACKUP_FILE=$2
TEMPLATES_BACKUP_FILE=$3
MEDIA_BACKUP_FILE=$4
IMAGES_BACKUP_FILE=$5

if [ -z "$DB_BACKUP_FILE" ] || [ -z "$HTML_BACKUP_FILE" ] || [ -z "$TEMPLATES_BACKUP_FILE" ] || [ -z "$MEDIA_BACKUP_FILE" ] || [ -z "$IMAGES_BACKUP_FILE" ]; then
  echo "❌ Usage: ./restore.sh <db-backup.sql.gz> <html.tar.gz> <templates.tar.gz> <media.tar.gz> <images.tar.gz>"
  echo "Example: ./restore.sh ./backups/my-joomla-backup_2025-06-26_20-00.sql.gz ./backups/joomla_html_2025-06-26_20-00.tar.gz ./backups/joomla_templates_2025-06-26_20-00.tar.gz ./backups/joomla_media_2025-06-26_20-00.tar.gz ./backups/joomla_images_2025-06-26_20-00.tar.gz"
  exit 1
fi

# === Step 1: Create the DB (if needed) ===
echo "🔧 Creating database if it doesn't exist..."
docker exec "$MYSQL_CONTAINER" sh -c "exec mysqladmin -u$DB_USER -p$DB_PASS create $DB_NAME" 2>/dev/null

# === Step 2: Restore database ===
echo "📥 Restoring database..."
gunzip < "$DB_BACKUP_FILE" | docker exec -i "$MYSQL_CONTAINER" sh -c \
  "exec mysql -h 127.0.0.1 -u$DB_USER -p$DB_PASS --force $DB_NAME"

if [ $? -eq 0 ]; then
  echo "✅ Database restore complete."
else
  echo "❌ Database restore failed!"
  exit 1
fi

# === Step 3: Restore Joomla volumes ===
echo "📦 Restoring Joomla HTML volume..."
docker run --rm \
  -v joomla-html:/to \
  -v "$BACKUP_DIR":/from \
  alpine sh -c "cd /to && tar xzf /from/$(basename "$HTML_BACKUP_FILE")"

echo "📦 Restoring Joomla template volume..."
docker run --rm \
  -v joomla-templates:/to \
  -v "$BACKUP_DIR":/from \
  alpine sh -c "cd /to && tar xzf /from/$(basename "$TEMPLATES_BACKUP_FILE")"

echo "📦 Restoring Joomla media volume..."
docker run --rm \
  -v joomla-media:/to \
  -v "$BACKUP_DIR":/from \
  alpine sh -c "cd /to && tar xzf /from/$(basename "$MEDIA_BACKUP_FILE")"

echo "📦 Restoring Joomla images volume..."
docker run --rm \
  -v joomla-images:/to \
  -v "$BACKUP_DIR":/from \
  alpine sh -c "cd /to && tar xzf /from/$(basename "$IMAGES_BACKUP_FILE")"

echo "🎉 Full restore completed successfully!"
