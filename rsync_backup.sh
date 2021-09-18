#!/bin/bash -

shopt -s lastpipe

PORT=22

SSH_CMD="ssh -v -p $PORT -i /home/$USER/.ssh/id_rsa"

SOURCE=$HOME

DESTINATION='/mnt/backup/'

TODAY="$(date +%Y-%m-%d-%H%M%S)"


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


printf "%s\n" "PERFORMING BACKUP. PLEASE WAIT..."

RSYNC_COPY="-a --stats --human-readable --progress --checksum --exclude={'__pycache__/','.pytest_cache/','.venv/','node_modules/','*.pyc'} --log-file=backup_$(date +%Y-%m-%d-%H%M%S).log"

START="$(date +%Hh:%Mm:%Ss)"

printf "%s" "$TODAY,$START" >> $HOME/backup_log.csv

rsync $SSH_CMD $RSYNC_COPY $SOURCE $DESTINATION | { awk '/total size is/{print $4}' | read TOTAL_SIZE; }

FINISH="$(date +%Hh:%Mm:%Ss)"

printf "%s\n" ",$FINISH,$TOTAL_SIZE,$SOURCE,$DESTINATION" >> $HOME/backup_log.csv

printf "%s\n" "BACKUP COMPLETE."

