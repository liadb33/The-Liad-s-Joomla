#!/bin/bash

# === Configuration ===
MYSQL_CONTAINER=joomla-mysql
DB_NAME=joomla
DB_USER=root
DB_PASS=my-secret-pw
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/backups"

# === Find latest backup files ===
DB_BACKUP_FILE=$(ls -t "$BACKUP_DIR"/*joomla-backup_*.sql.gz 2>/dev/null | head -n 1)
HTML_BACKUP_FILE=$(ls -t "$BACKUP_DIR"/joomla_html_*.tar.gz 2>/dev/null | head -n 1)
TEMPLATES_BACKUP_FILE=$(ls -t "$BACKUP_DIR"/joomla_templates_*.tar.gz 2>/dev/null | head -n 1)
MEDIA_BACKUP_FILE=$(ls -t "$BACKUP_DIR"/joomla_media_*.tar.gz 2>/dev/null | head -n 1)
IMAGES_BACKUP_FILE=$(ls -t "$BACKUP_DIR"/joomla_images_*.tar.gz 2>/dev/null | head -n 1)

# === Verify all files found ===
if [ -z "$DB_BACKUP_FILE" ] || [ -z "$HTML_BACKUP_FILE" ] || [ -z "$TEMPLATES_BACKUP_FILE" ] || [ -z "$MEDIA_BACKUP_FILE" ] || [ -z "$IMAGES_BACKUP_FILE" ]; then
  echo "❌ Could not find all required backup files in $BACKUP_DIR"
  echo "Make sure the folder contains:"
  echo "- my-joomla-backup_*.sql.gz"
  echo "- joomla_html_*.tar.gz"
  echo "- joomla_templates_*.tar.gz"
  echo "- joomla_media_*.tar.gz"
  echo "- joomla_images_*.tar.gz"
  exit 1
fi

# === Step 1: Create the DB (if needed) ===
echo "🔧 Creating database if it doesn't exist..."
docker exec "$MYSQL_CONTAINER" sh -c "exec mysqladmin -u$DB_USER -p$DB_PASS create $DB_NAME" 2>/dev/null

# === Step 2: Restore database ===
echo "📥 Restoring database from: $(basename "$DB_BACKUP_FILE")"
gunzip < "$DB_BACKUP_FILE" | docker exec -i "$MYSQL_CONTAINER" sh -c \
  "exec mysql -h 127.0.0.1 -u$DB_USER -p$DB_PASS --force $DB_NAME"

if [ $? -eq 0 ]; then
  echo "✅ Database restore complete."
else
  echo "❌ Database restore failed!"
  exit 1
fi

# === Step 3: Restore Joomla volumes ===
echo "📦 Restoring Joomla HTML volume from: $(basename "$HTML_BACKUP_FILE")"
docker run --rm \
  -v joomla-html:/to \
  -v "$BACKUP_DIR":/from \
  alpine sh -c "cd /to && tar xzf /from/$(basename "$HTML_BACKUP_FILE")"

echo "📦 Restoring Joomla template volume from: $(basename "$TEMPLATES_BACKUP_FILE")"
docker run --rm \
  -v joomla-templates:/to \
  -v "$BACKUP_DIR":/from \
  alpine sh -c "cd /to && tar xzf /from/$(basename "$TEMPLATES_BACKUP_FILE")"

echo "📦 Restoring Joomla media volume from: $(basename "$MEDIA_BACKUP_FILE")"
docker run --rm \
  -v joomla-media:/to \
  -v "$BACKUP_DIR":/from \
  alpine sh -c "cd /to && tar xzf /from/$(basename "$MEDIA_BACKUP_FILE")"

echo "📦 Restoring Joomla images volume from: $(basename "$IMAGES_BACKUP_FILE")"
docker run --rm \
  -v joomla-images:/to \
  -v "$BACKUP_DIR":/from \
  alpine sh -c "cd /to && tar xzf /from/$(basename "$IMAGES_BACKUP_FILE")"

echo "🎉 Full restore completed successfully!"
