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

echo "📋 Found backup files:"
echo "  DB: $(basename "$DB_BACKUP_FILE")"
echo "  HTML: $(basename "$HTML_BACKUP_FILE")"
echo "  Templates: $(basename "$TEMPLATES_BACKUP_FILE")"
echo "  Media: $(basename "$MEDIA_BACKUP_FILE")"
echo "  Images: $(basename "$IMAGES_BACKUP_FILE")"
echo ""

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
  
  # Clear the target directory first (except for html root to avoid breaking container)
  if [ "$container_path" != "/var/www/html" ]; then
    docker exec "$JOOMLA_CONTAINER" sh -c "rm -rf $container_path/*" 2>/dev/null
  fi
  
  # Create directory if it doesn't exist
  docker exec "$JOOMLA_CONTAINER" sh -c "mkdir -p $container_path"
  
  # Extract files directly without copying to tmp (more efficient and preserves permissions better)
  cat "$tar_file" | docker exec -i "$JOOMLA_CONTAINER" sh -c "tar xzf - -C $container_path"
  
  if [ $? -eq 0 ]; then
    echo "✅ $label restored successfully"
  else
    echo "❌ Failed to restore $label"
    exit 1
  fi
}

# Restore files in correct order
restore_to_container "$HTML_BACKUP_FILE" "/var/www/html" "Joomla core"
restore_to_container "$TEMPLATES_BACKUP_FILE" "/var/www/html/templates/cassiopeia" "templates"
restore_to_container "$MEDIA_BACKUP_FILE" "/var/www/html/media" "media"
restore_to_container "$IMAGES_BACKUP_FILE" "/var/www/html/images" "images"

# === Step 4: Fix file permissions ===
echo "🔧 Fixing file permissions and ownership..."
docker exec "$JOOMLA_CONTAINER" sh -c "
  # Set proper ownership
  chown -R www-data:www-data /var/www/html
  
  # Set file permissions (644 for files, 755 for directories)
  find /var/www/html -type f -exec chmod 644 {} \;
  find /var/www/html -type d -exec chmod 755 {} \;
  
  # Special permissions for configuration file (if it exists)
  if [ -f /var/www/html/configuration.php ]; then
    chmod 644 /var/www/html/configuration.php
    chown www-data:www-data /var/www/html/configuration.php
  fi
  
  # Ensure writable directories for Joomla
  chmod 755 /var/www/html/tmp 2>/dev/null || true
  chmod 755 /var/www/html/logs 2>/dev/null || true
  chmod 755 /var/www/html/cache 2>/dev/null || true
  chmod 755 /var/www/html/administrator/cache 2>/dev/null || true
  chmod 755 /var/www/html/images 2>/dev/null || true
  chmod 755 /var/www/html/media 2>/dev/null || true
"

if [ $? -eq 0 ]; then
  echo "✅ File permissions fixed successfully"
else
  echo "⚠️  Warning: Some permission fixes may have failed, but continuing..."
fi

# === Step 5: Restart containers to ensure clean state ===
echo "🔄 Restarting containers for clean state..."
docker restart "$JOOMLA_CONTAINER" >/dev/null 2>&1

# Wait a moment for container to fully restart
echo "⏳ Waiting for container to restart..."
sleep 5

# Check if container is running
if docker ps | grep -q "$JOOMLA_CONTAINER"; then
  echo "✅ Container restarted successfully"
else
  echo "⚠️  Warning: Container may not have restarted properly"
fi

echo ""
echo "🎉 Full restore completed successfully!"
