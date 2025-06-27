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

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "📦 Starting backup process..."
echo "Timestamp: $TIMESTAMP"
echo ""

# === Step 1: Backup MySQL database ===
echo "📦 Backing up MySQL database..."
docker exec "$MYSQL_CONTAINER" sh -c \
  "exec mysqldump --all-databases -uroot -p$MYSQL_ROOT_PASSWORD" | gzip > "$DB_BACKUP_FILE"

if [ $? -eq 0 ]; then
  echo "✅ DB backup saved: $(basename "$DB_BACKUP_FILE")"
else
  echo "❌ DB backup failed."
  exit 1
fi

# === Step 2: Backup Joomla files (complete) ===
echo "📁 Backing up complete Joomla installation (/var/www/html)..."
docker exec "$JOOMLA_CONTAINER" sh -c \
  "tar czf - -C /var/www/html ." > "$HTML_BACKUP_FILE"

if [ $? -eq 0 ]; then
  echo "✅ Joomla files backup saved: $(basename "$HTML_BACKUP_FILE")"
else
  echo "❌ Joomla files backup failed."
  exit 1
fi

# === Step 3: Display backup summary ===
echo ""
echo "🎉 All backups completed successfully!"
echo ""
echo "📋 Backup summary:"
echo "  📄 Database: $(basename "$DB_BACKUP_FILE")"
echo "  📁 Files: $(basename "$HTML_BACKUP_FILE")"
echo "  📂 Location: $BACKUP_DIR"
echo ""

# Display file sizes
if command -v du >/dev/null 2>&1; then
  echo "📊 Backup sizes:"
  echo "  Database: $(du -h "$DB_BACKUP_FILE" | cut -f1)"
  echo "  Files: $(du -h "$HTML_BACKUP_FILE" | cut -f1)"
fi
