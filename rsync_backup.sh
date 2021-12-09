#!/bin/bash -

shopt -s lastpipe

PORT=22

SSH_CMD="ssh -p $PORT -i /home/$USER/.ssh/id_rsa"

SOURCE=$HOME

DESTINATION='/mnt/backup/'

TODAY="$(date +%Y-%m-%d_%H:%M:%S)"


if [ -d $DESTINATION ]; then
    printf "%s\n" "BACKUP DRIVE MOUNTED."
else
    printf "%s\n" "MOUNTING BACKUP DRIVE..."
    mount -v $DESTINATION
    if [ "$(echo $?)" -eq 0 ]; then
        printf "%s\n" "${TODAY},'ERROR! BACKUP DRIVE NOT ACCESSIBLE.'" >> $HOME/backup_log.csv
        exit 1
    fi
fi


function run_backup() {
    printf "%s\n" "PERFORMING BACKUP. PLEASE WAIT..."

    RSYNC_COPY="-a --stats --human-readable --progress --checksum --exclude={'__pycache__/','.pytest_cache/','.venv/','node_modules/','*.pyc'} --log-file=backup_$(date +%Y-%m-%d_%H%M%S).log"

    START="$(date +%Hh:%Mm:%Ss)"
    
    logger "STARTING BACKUP: $START"

    BACKUP_START=$SECONDS

    printf "%s" "$TODAY,$START" >> $HOME/backup_log.csv

    rsync -e $SSH_CMD $RSYNC_COPY $SOURCE $DESTINATION | { awk '/total size is/{print $4}' | read TOTAL_SIZE; }

    BACKUP_FINISH=$SECONDS

    TOTAL_SECONDS="$((BACKUP_FINISH - BACKUP_START))"

    ELAPSED_TIME="$(($TOTAL_SECONDS / 3600))h:$(($TOTAL_SECONDS / 60))m:$(($TOTAL_SECONDS % 60))s"

    FINISH="$(date +%Hh:%Mm:%Ss)"
    
    logger "FINISHING BACKUP: $FINISH"

    printf "%s\n" ",$FINISH,$ELAPSED_TIME,$TOTAL_SIZE,$SOURCE,$DESTINATION" >> $HOME/backup_log.csv

    printf "%s\n" "BACKUP COMPLETE."
}


if [ "$(cat today.tmp)" != "$(date +%d)" ]; then
    run_backup
    date +%d > today.tmp
fi
