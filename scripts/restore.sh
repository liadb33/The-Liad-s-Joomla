#!/bin/bash

# === Configuration ===
MYSQL_CONTAINER=joomla-mysql
JOOMLA_CONTAINER=joomla
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

# === Step 1: Create DB (if needed) ===
echo "🔧 Creating database if it doesn't exist..."
docker exec "$MYSQL_CONTAINER" sh -c "exec mysqladmin -u$DB_USER -p$DB_PASS create $DB_NAME" 2>/dev/null

# === Step 2: Restore DB ===
echo "📥 Restoring database from: $(basename "$DB_BACKUP_FILE")"
gunzip < "$DB_BACKUP_FILE" | docker exec -i "$MYSQL_CONTAINER" sh -c \
  "exec mysql -h 127.0.0.1 -u$DB_USER -p$DB_PASS --force $DB_NAME"

if [ $? -eq 0 ]; then
  echo "✅ Database restore complete."
else
  echo "❌ Database restore failed!"
  exit 1
fi

# === Step 3: Restore Joomla files ===

restore_to_container() {
  local tar_file=$1
  local container_path=$2
  local label=$3

  echo "📦 Restoring $label from: $(basename "$tar_file")"
  docker cp "$tar_file" "$JOOMLA_CONTAINER":/tmp/restore.tar.gz
  docker exec "$JOOMLA_CONTAINER" sh -c "mkdir -p $container_path && tar xzf /tmp/restore.tar.gz -C $container_path && rm /tmp/restore.tar.gz"
}

restore_to_container "$HTML_BACKUP_FILE" "/var/www/html" "Joomla core"
restore_to_container "$TEMPLATES_BACKUP_FILE" "/var/www/html/templates/cassiopeia" "templates"
restore_to_container "$MEDIA_BACKUP_FILE" "/var/www/html/media" "media"
restore_to_container "$IMAGES_BACKUP_FILE" "/var/www/html/images" "images"

echo "🎉 Full restore completed successfully!"
