#!/bin/bash
set -e
cd $BASE_DIR
export DATA_DIR=${DATA_DIR:-/data}
export ZEO_LOGFILES=${ZEO_LOGFILES:-$DATA_DIR/log/zeo.log}
SDEBUG=${SDEBUG-}
DEBUG=${DEBUG:-${SDEBUG-}}
VCOMMAND=""
DASHVCOMMAND=""
export SHELL_USER="${SHELL_USER:-root}" SHELL_EXECUTABLE="${SHELL_EXECUTABLE:-/bin/bash}"
cfgs="
/etc/logrotate.d/plone.frep
/etc/supervisor.d/zeo.frep
/etc/supervisor.d/zeotail.frep
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
for i in $cfgs;do
    vv frep "init$i:$(dirname $i)/$(basename $i .frep)" --overwrite
done
# upstream logs to stdout
# minimal wrapper to launch sidekar cron, logrotate & rsyslog
if [ "x${@}" = "x" ]; then
    SUPERVISORD_CONFIGS="zeotail zeo rsyslog cron" exec supervisord.sh
else
    if [ "x${1-}" = "xshell" ];then shift;fi
    # retrocompat with old images
    cmd="${@:-bash}"
    ( user=$SHELL_USER _shell "$cmd" )
fi
