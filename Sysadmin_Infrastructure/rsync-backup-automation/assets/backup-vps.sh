#!/bin/bash
#

REMOTE_HOST="vps2"
REMOTE_PATH="~/VPS_Backups/www"
LOCAL_PATH="/var/www"
LOG_FILE="/var/log/backup.log"

DATE=$(date +%Y-%m-%d_%H:%M:%S)
MAX_LOG_LINES=1000


log() {
	echo "[${DATE}] $1" >> "${LOG_FILE}"
}

log "--- Backup Started ---"
log "Source : ${LOCAL_PATH} -> ${REMOTE_HOST}:${REMOTE_PATH}"

rsync -az --stats \
	--exclude="*.log" \
	--exclude="*.tmp" \
	--delete \
	${LOCAL_PATH}/ ${REMOTE_HOST}:${REMOTE_PATH}/ >> "${LOG_FILE}" 2>&1



EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
	log "Backup completed successfully"
else 
	log "Backup FAILED with exit code ${EXIT_CODE}"
fi


tail -n ${MAX_LOG_LINES} "${LOG_FILE}" > "${LOG_FILE}.tmp"
mv "${LOG_FILE}.tmp" "${LOG_FILE}"

exit $EXIT_CODE
