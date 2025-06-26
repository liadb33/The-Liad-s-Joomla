#!/bin/bash

# === Configuration ===
MYSQL_CONTAINER=joomla-mysql
JOOMLA_CONTAINER=joomla
MYSQL_ROOT_PASSWORD=my-secret-pw
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# === Output paths ===
DB_BACKUP_FILE=$BACKUP_DIR/my-joomla-backup_$TIMESTAMP.sql.gz
HTML_BACKUP_FILE=$BACKUP_DIR/joomla_html_$TIMESTAMP.tar.gz
TEMPLATES_BACKUP_FILE=$BACKUP_DIR/joomla_templates_$TIMESTAMP.tar.gz
MEDIA_BACKUP_FILE=$BACKUP_DIR/joomla_media_$TIMESTAMP.tar.gz
IMAGES_BACKUP_FILE=$BACKUP_DIR/joomla_images_$TIMESTAMP.tar.gz

mkdir -p "$BACKUP_DIR"

echo "📦 Backing up MySQL database..."
docker exec "$MYSQL_CONTAINER" sh -c \
  "exec mysqldump --all-databases -uroot -p$MYSQL_ROOT_PASSWORD" | gzip > "$DB_BACKUP_FILE"

if [ $? -eq 0 ]; then
  echo "✅ DB backup saved: $DB_BACKUP_FILE"
else
  echo "❌ DB backup failed."
  exit 1
fi

echo "📁 Backing up Joomla core (/var/www/html)..."
docker exec "$JOOMLA_CONTAINER" sh -c \
  "tar czf - -C /var/www/html ." > "$HTML_BACKUP_FILE"

echo "📁 Backing up templates..."
docker exec "$JOOMLA_CONTAINER" sh -c \
  "tar czf - -C /var/www/html/templates/cassiopeia ." > "$TEMPLATES_BACKUP_FILE"

echo "📁 Backing up media..."
docker exec "$JOOMLA_CONTAINER" sh -c \
  "tar czf - -C /var/www/html/media ." > "$MEDIA_BACKUP_FILE"

echo "📁 Backing up images..."
docker exec "$JOOMLA_CONTAINER" sh -c \
  "tar czf - -C /var/www/html/images ." > "$IMAGES_BACKUP_FILE"

echo "🎉 All backups completed successfully!"
