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

# === Determine backup files ===
if [ -z "$1" ]; then
  DB_BACKUP_FILE=$(ls -t "$BACKUP_DIR"/my-joomla-backup_*.sql.gz 2>/dev/null | head -n 1)
else
  DB_BACKUP_FILE=$1
fi

if [ -z "$2" ]; then
  VOLUME_BACKUP_FILE=$(ls -t "$BACKUP_DIR"/joomla_html_*.tar.gz 2>/dev/null | head -n 1)
else
  VOLUME_BACKUP_FILE=$2
fi

# === Validate backup files ===
if [ ! -f "$DB_BACKUP_FILE" ] || [ ! -f "$VOLUME_BACKUP_FILE" ]; then
  echo "❌ Could not find the required backup files."
  echo "Make sure files exist in $BACKUP_DIR or provide them manually."
  exit 1
fi

echo "🔄 Using database backup: $DB_BACKUP_FILE"
echo "🔄 Using volume backup: $VOLUME_BACKUP_FILE"

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

# === Step 3: Restore Joomla volume ===
echo "📁 Restoring Joomla site files into volume..."
docker run --rm \
  -v joomla-html:/to \
  -v "$BACKUP_DIR":/from \
  alpine sh -c "cd /to && tar xzf /from/$(basename "$VOLUME_BACKUP_FILE")"

if [ $? -eq 0 ]; then
  echo "✅ Joomla files restored to volume."
else
  echo "❌ Joomla volume restore failed!"
  exit 1
fi

# === Step 4: Restart Joomla ===
echo "🔄 Restarting Joomla container..."
docker restart "$JOOMLA_CONTAINER"

echo "🎉 Restore completed successfully."
