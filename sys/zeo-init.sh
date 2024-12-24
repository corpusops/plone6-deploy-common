#!/bin/bash
set -e
cd $BASE_DIR
export IMAGE_MODE="${IMAGE_MODE:-zeo}"
export DATA_DIR=${DATA_DIR:-/data}
export ZEO_LOGFILES=${ZEO_LOGFILES:-$DATA_DIR/log/zeo.log}
export DEFAULT_PLONE_BACKUP_KEEP_DAYS="${DEFAULT_PLONE_BACKUP_KEEP_DAYS:-77}"
export PLONE_BACKUP_KEEP_DAYS="${PLONE_BACKUP_KEEP_DAYS:-2}"
export APP_USER="plone"
export APP_GROUP="plone"

SDEBUG=${SDEBUG-}
DEBUG=${DEBUG:-${SDEBUG-}}
VCOMMAND=""
DASHVCOMMAND=""
export SHELL_USER="${SHELL_USER:-root}" SHELL_EXECUTABLE="${SHELL_EXECUTABLE:-/bin/bash}"
export PLONE_DATA_DIR="${PLONE_DATA_DIR:-/data}"
export PLONE_BACKUP_DIR="${PLONE_BACKUP_DIR:-/backup}"
export PLONE_BACKUP_DIRS="${PLONE_BACKUP_DIRS:-"
/app/data/logs/cron
$PLONE_BACKUP_DIR
$PLONE_BACKUP_DIR/snapshot
$PLONE_BACKUP_DIR/snapshot/filestorage
$PLONE_BACKUP_DIR/snapshot/blob
$PLONE_BACKUP_DIR/daily
$PLONE_BACKUP_DIR/daily/filestorage
$PLONE_BACKUP_DIR/daily/blob
$PLONE_BACKUP_DIR/blobstoragezips
$PLONE_BACKUP_DIR/zipbackups
"}"
cfgs="
/etc/logrotate.d/plone.frep
/etc/supervisor.d/zeo.frep
/etc/supervisor.d/zeotail.frep
/etc/cron.d/plonebackup.frep
"
if [[ -n $SDEBUG ]];then set -x; VCOMMAND="v"; VDEBUG="v"; DASHVCOMMAND="-v";fi
debuglog() { if [[ -n "$DEBUG" ]];then echo "$@" >&2;fi }
log() { echo "$@" >&2; }
die() { log "$@";exit 1; }
vv() { log "$@";"$@"; }
dvv() { debuglog "$@";"$@"; }
_shell() {
    exec gosu ${SHELL_USER} $SHELL_EXECUTABLE -$([[ -n ${SSDEBUG:-$SDEBUG} ]] && echo "x" )elc "${@:-${SHELL_EXECUTABLE}}"
}
# we have two types of CRONTABS, one dedicated to backup and one to application
rm -fv $(find  /etc/*cron* -name "*plone*" |grep -v backup|xargs rm -rfv)
setupdir() {
    if [ ! -e "$1" ];then mkdir -pv "$1";fi
    chown plone $1
}

# fixperms: basic file & ownership enforcement
fixperms() {
    if [[ -n $NO_FIXPERMS ]];then return 0;fi
    for i in $PLONE_BACKUP_DIRS $PLONE_DATA_DIR $PLONE_DATA_DIR/filestorage;do setupdir $i;done
    # plone specific: do not go totally down in data folders for performance !
    while read f;do chown -v ${APP_USER}:${APP_GROUP} "$f"&done < \
        <(find /data -not -user ${APP_USER} -maxdepth 2)
    # end: plone specific
    wait
}
fixperms
for i in $cfgs;do vv frep "init$i:$(dirname $i)/$(basename $i .frep)" --overwrite;done
for i in $PLONE_DATA_DIR/*;do setupdir $i;done
# configure backups
for i in bin/snapshotbackup bin/fullbackup bin/backup bin/snapshotrestore bin/restore;do
    if [ -e $i ];then
        sed -i -re "s/=$DEFAULT_PLONE_BACKUP_KEEP_DAYS,/=$PLONE_BACKUP_KEEP_DAYS,/g;" "$i"
    fi
done
# upstream logs to stdout
# minimal wrapper to launch sidekar cron, logrotate & rsyslog
if [ "x${IMAGE_MODE}" = "xbackup" ]; then
    sed -i -re "/data\/log\/.log/d" /etc/logrotate.d/plone
    SUPERVISORD_CONFIGS="rsyslog cron" exec supervisord.sh
elif [ "x${@}" = "x" ]; then
    rm -f /etc/cron.d/plonebackup
    sed -i -re "/logs.*crons/d"  /etc/logrotate.d/plone
    SUPERVISORD_CONFIGS="zeotail zeo rsyslog cron" exec supervisord.sh
else
    if [ "x${1-}" = "xshell" ];then shift;fi
    # retrocompat with old images
    cmd="${@:-bash}"
    ( user=$SHELL_USER _shell "$cmd" )
fi
