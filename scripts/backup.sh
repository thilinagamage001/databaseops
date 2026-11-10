#!/bin/bash

# Configuration
CONTAINER_NAME="postgres_lab"
DB_USER="postgres_admin"
DB_NAME="company_db"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_$TIMESTAMP.dump"
CONTAINER_TMP_PATH="/tmp/${DB_NAME}_temp.dump"
LOG_FILE="$BACKUP_DIR/backup.log"
RETENTION_DAYS=7

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting backup for $DB_NAME..." >> "$LOG_FILE"

# 1. Generate dump inside the container (avoids TTY binary stream corruption)
docker exec "$CONTAINER_NAME" pg_dump -U "$DB_USER" -d "$DB_NAME" -F c -f "$CONTAINER_TMP_PATH"

if [ $? -eq 0 ]; then
    # 2. Copy the dump file safely from container to host
    docker cp "$CONTAINER_NAME:$CONTAINER_TMP_PATH" "$BACKUP_FILE"
    
    # 3. Clean up temp file inside container
    docker exec "$CONTAINER_NAME" rm -f "$CONTAINER_TMP_PATH"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: Backup created at $BACKUP_FILE" >> "$LOG_FILE"
    
    # Enforce retention policy: Delete backups older than RETENTION_DAYS
    find "$BACKUP_DIR" -name "${DB_NAME}_*.dump" -mtime +$RETENTION_DAYS -exec rm {} \;
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] CLEANUP: Removed backups older than $RETENTION_DAYS days." >> "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Backup failed for $DB_NAME!" >> "$LOG_FILE"
    exit 1
fi
