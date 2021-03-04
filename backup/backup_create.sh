#!/bin/bash

TODAY=$(date +%Y-%m-%d)
DATADIR=/home/pi/docker/
BACKUPDIR=/mnt/MyDrive/
SCRIPTDIR=/home/pi/docker/
LASTDAYPATH=${BACKUPDIR}/$(ls ${BACKUPDIR} | tail -n 1)
TODAYPATH=${BACKUPDIR}/${TODAY}
if [[ ! -e ${TODAYPATH} ]]; then
        mkdir -p ${TODAYPATH}
fi

rsync -a --link-dest ${LASTDAYPATH} ${DATADIR} ${TODAYPATH} $@
