#!/bin/bash

# Configuration
CONTAINER_NAME="postgres_lab"
DB_USER="postgres_admin"
BACKUP_DIR="./backups"
TARGET_DB="company_db_restored"

# Check if a backup file was provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <backup_filename>"
    echo "Available backups in $BACKUP_DIR:"
    ls -1 "$BACKUP_DIR"/*.dump 2>/dev/null || echo "No backups found."
    exit 1
fi

BACKUP_PATH="$1"

if [ ! -f "$BACKUP_PATH" ]; then
    echo "Error: Backup file '$BACKUP_PATH' not found!"
    exit 1
fi

echo "Starting restoration from $BACKUP_PATH into target database '$TARGET_DB'..."

# 1. Drop and recreate the target verification database
docker exec -t "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS $TARGET_DB;"
docker exec -t "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres -c "CREATE DATABASE $TARGET_DB;"

# 2. Copy backup into container and restore using pg_restore
CONTAINER_BACKUP_PATH="/tmp/restore_target.dump"
docker cp "$BACKUP_PATH" "$CONTAINER_NAME:$CONTAINER_BACKUP_PATH"

docker exec -t "$CONTAINER_NAME" pg_restore -U "$DB_USER" -d "$TARGET_DB" --clean --if-exists "$CONTAINER_BACKUP_PATH"

if [ $? -eq 0 ]; then
    echo "SUCCESS: Database restored successfully to '$TARGET_DB'."
    
    # 3. Verify row counts in the restored database
    echo "Verifying row counts..."
    docker exec -t "$CONTAINER_NAME" psql -U "$DB_USER" -d "$TARGET_DB" -c "
        SELECT 'departments' AS table_name, COUNT(*) FROM departments
        UNION ALL
        SELECT 'employees', COUNT(*) FROM employees
        UNION ALL
        SELECT 'transactions', COUNT(*) FROM transactions;
    "
else
    echo "ERROR: Restoration failed."
    exit 1
fi
