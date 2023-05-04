#!/bin/bash
# If you need more debug play with these variables:
# export NO_STARTUP_LOGS=
# export SHELL_DEBUG=1
# export DEBUG=1
# start by the first one, then try the others
export SCRIPTSDIR="$(dirname $(readlink -f "$0"))"
SDEBUG=${SDEBUG-}
DEBUG=${DEBUG:-${SDEBUG-}}
# activate shell debug if SDEBUG is set
VCOMMAND=""
DASHVCOMMAND=""
if [[ -n $SDEBUG ]];then set -x; VCOMMAND="v"; VDEBUG="v"; DASHVCOMMAND="-v";fi
ODIR=$(pwd)
cd "${TOPDIR:-$SCRIPTSDIR/..}"
TOPDIR="$(pwd)"
BASE_DIR="${BASE_DIR:-${TOPDIR}}"

# now be in stop-on-error mode
set -e
PYCHARM_DIRS="${PYCHARM_DIRS:-"/opt/pycharm /opt/.pycharm /opt/.pycharm_helpers"}"
OPYPATH="${PYTHONPATH-}"
for i in $PYCHARM_DIRS;do if [ -e "$i" ];then IMAGE_MODE="${FORCE_IMAGE_MODE-pycharm}";break;fi;done

# load locales & default env while preserving original $PATH
export OPATH=$PATH
for i in /etc/environment /etc/default/locale;do if [ -e $i ];then . $i;fi;done
export PATH=$OPATH

# load virtualenv if present
for VENV in "$BASE_DIR/venv" "$BASE_DIR";do if [ -e "$VENV/bin/activate" ];then export VENV;. "$VENV/bin/activate";break;fi;done

SRC_DIR="${SRC_DIR-}"
SRC_DIR_NAME=src
if [[ -z "${SRC_DIR}" ]];then
    if [ -e "${TOPDIR}/${SRC_DIR_NAME}" ];then SRC_DIR="$TOPDIR/${SRC_DIR_NAME}";fi
fi

DEFAULT_IMAGE_MODE="plone"

export IMAGE_MODE=${IMAGE_MODE:-${DEFAULT_IMAGE_MODE}}
SKIP_STARTUP_DB=${SKIP_STARTUP_DB-}
SKIP_SYNC_DOCS=${SKIP_SYNC_DOCS-}
IMAGE_MODES="(shell|cron|backup|plone|fg)"
IMAGE_MODES_MIGRATE="(fg|plone)"
NO_START=${NO_START-}
PLONE_CONF_PREFIX="${PLONE_CONF_PREFIX:-"PLONE__"}"
DEFAULT_NO_COMPILE_MESSAGES=
DEFAULT_NO_STARTUP_LOGS=
DEFAULT_NO_COLLECT_STATIC=
if ( echo $IMAGE_MODE|grep -E -iq "$IMAGE_MODES_MIGRATE" );then
    DEFAULT_NO_MIGRATE=
fi
if [[ -n $@ ]];then
    IMAGE_MODE=shell
    DEFAULT_NO_MIGRATE=1
    DEFAULT_NO_COMPILE_MESSAGES=1
    DEFAULT_NO_COLLECT_STATIC=1
    DEFAULT_NO_STARTUP_LOGS=1
fi
NO_MIGRATE=${NO_MIGRATE-$DEFAULT_NO_MIGRATE}
NO_STARTUP_LOGS=${NO_STARTUP_LOGS-$DEFAULT_NO_STARTUP_LOGS}
NO_COMPILE_MESSAGES=${NO_COMPILE_MESSAGES-$DEFAULT_NO_COMPILE_MESSAGES}
NO_COLLECT_STATIC=${NO_COLLECT_STATIC-$DEFAULT_NO_COLLECT_STATIC}
NO_IMAGE_SETUP="${NO_IMAGE_SETUP:-"1"}"
SKIP_IMAGE_SETUP="${KIP_IMAGE_SETUP:-""}"
FORCE_IMAGE_SETUP="${FORCE_IMAGE_SETUP:-"1"}"
SKIP_SERVICES_SETUP="${SKIP_SERVICES_SETUP-}"
IMAGE_SETUP_MODES="${IMAGE_SETUP_MODES:-"fg|gunicorn"}"
EP_CUSTOM_ACTIONS="compile_messages|fixperms|"
export PIP_SRC=${PIP_SRC:-${BASE_DIR}/pipsrc}
export LOCAL_DIR="${LOCAL_DIR:-/local}"
NO_PIPENV_INSTALL=${NO_PIPENV_INSTALL-1}
PIPENV_INSTALL_ARGS="${PIPENV_INSTALL_ARGS-"--ignore-pipfile"}"
# log to stdout which in turn should log to docker logger, do not store local logs
export RSYSLOG_LOGFORMAT="${RSYSLOG_LOGFORMAT:-'%timegenerated% %syslogtag% %msg%\\n'}"
export RSYSLOG_OUT_LOGFILE="${RSYSLOG_OUT_LOGFILE:-n}"
export RSYSLOG_REPEATED_MSG_REDUCTION="${RSYSLOG_REPEATED_MSG_REDUCTION:-off}"
FINDPERMS_PERMS_DIRS_CANDIDATES="${FINDPERMS_PERMS_DIRS_CANDIDATES:-"sys/etc/cron.d"}"
PLONE_LOCATIONS="
$BASE_DIR/scripts
$BASE_DIR/inituser
$BASE_DIR/etc
$BASE_DIR/docker-entrypoint.sh
$BASE_DIR/pyvenv.cfg
$BASE_DIR/lib64
$BASE_DIR/lib
$BASE_DIR/constraints.txt
$BASE_DIR/include
$BASE_DIR/bin
/compile_mo.py
"
FINDPERMS_OWNERSHIP_DIRS_CANDIDATES="${FINDPERMS_OWNERSHIP_DIRS_CANDIDATES:-"/home/$APP_USER/.cache/pip $BASE_DIR/sources $LOCAL_DIR data $PLONE_LOCATIONS"}"
SKIP_RENDERED_CONFIGS="${SKIP_RENDERED_CONFIGS:-varnish}"
export HISTFILE="${LOCAL_DIR}/.bash_history"
export PSQL_HISTORY="${LOCAL_DIR}/.psql_history"
export MYSQL_HISTFILE="${LOCAL_DIR}/.mysql_history"
export IPYTHONDIR="${LOCAL_DIR}/.ipython"

export CRON_LOGS_DIRS="${CRON_LOGS_DIRS:-"data/flags data/logs/cron /logs/cron"}"
export APP_TYPE="${APP_TYPE:-plone}"
export TMPDIR="${TMPDIR:-/tmp}"
export STARTUP_LOG="${STARTUP_LOG:-$TMPDIR/${APP_TYPE}_startup.log}"
export APP_USER="${APP_USER:-$APP_TYPE}"
export HOST_USER_UID="${HOST_USER_UID:-$(id -u $APP_USER)}"
export INIT_HOOKS_DIR="${INIT_HOOKS_DIR:-${BASE_DIR}/sys/scripts/hooks}"
export APP_GROUP="${APP_GROUP:-$APP_USER}"
export EXTRA_USER_DIRS="${EXTRA_USER_DIRS-}"
export USER_DIRS="${USER_DIRS:-". .tox src sources data /data $CRON_LOGS_DIRS $LOCAL_DIR ${EXTRA_USER_DIRS} /home/${APP_USER}/.ssh /home/${APP_USER}"}"
export SHELL_USER="${SHELL_USER:-${APP_USER}}" SHELL_EXECUTABLE="${SHELL_EXECUTABLE:-/bin/bash}"
export SKIP_REGEN_EGG_INFO="${SKIP_REGEN_EGG_INFO-}"

# plone specific settings
export DB_MODE="${DB_MODE:-zeo}"
export ZEO_ADDRESS="${ZEO_ADDRESS:-"db:8100"}"
if [[ -z ${RELSTORAGE_DSN} ]];then unset RELSTORAGE_DSN;fi
if [[ -z ${ZEO_ADDRESS} ]];then unset ZEO_ADDRESS;fi

export PLONE_ADMIN_PASSWORD="${PLONE_ADMIN_PASSWORD:-admin}"
export PLONE_PROFILES="${PLONE_PROFILES:-}"
export PLONE_TYPE="${PLONE_TYPE:-classic}"
export PLONE_SITE="${PLONE_SITE:-Plone}"
export ZODB_CACHE_SIZE="${ZODB_CACHE_SIZE:-50000}"
export ZEO_CLIENT_CACHE_SIZE="${ZEO_CLIENT_CACHE_SIZE:-128MB}"
# plone cors configuration
export CORS_ALLOW_ORIGIN="${CORS_ALLOW_ORIGIN:-"*"}"
export CORS_ALLOW_METHODS="${CORS_ALLOW_METHODS:-"DELETE,GET,OPTIONS,PATCH,POST,PUT"}"
export CORS_ALLOW_CREDENTIALS="${CORS_ALLOW_CREDENTIALS:-"true"}"
export CORS_EXPOSE_HEADERS="${CORS_EXPOSE_HEADERS:-"Content-Length,X-My-Header"}"
export CORS_ALLOW_HEADERS="${CORS_ALLOW_HEADERS:-"Authorization,Content-Type,Accept,Origin,User-Agent,DNT,Cache-Control,X-Mx-ReqToken,Keep-Alive,X-Requested-With,If-Modified-Since"}"
export CORS_MAX_AGE="${CORS_MAX_AGE:-"3600"}"
# 10TB should be enougth
export MAX_REQUEST_BODY_SIZE="${MAX_REQUEST_BODY_SIZE:-"$((10*1024*1024*1024*1024))"}"

# tox variables
export TOX_DIRECT=${TOX_DIRECT-1}
export TOX_DIRECT_YOLO=${TOX_DIRECT_YOLO-1}
if [[ -z "$TOX_DIRECT_YOLO" ]];then unset TOX_DIRECT_YOLO;fi
if [[ -z "$TOX_DIRECT" ]];then unset TOX_DIRECT;fi
for tdir in "$SRC_DIR" "$TOPDIR";do for tini in tox.ini setup.cfg;do
    toxini="$tdir/$tini";if [ -e $toxinit ];then export TOX_CONFIG_FILE="$toxini";break;fi
done;done

# forward console integration
export TERM="${TERM-}" COLUMNS="${COLUMNS-}" LINES="${LINES-}"

debuglog() { if [[ -n "$DEBUG" ]];then echo "$@" >&2;fi }
log() { echo "$@" >&2; }
die() { log "$@";exit 1; }
vv() { log "$@";"$@"; }
dvv() { debuglog "$@";"$@"; }

# Regenerate egg-info & be sure to have it in site-packages
regen_egg_info() {
    local f="$1"
    if [ -e "$f" ];then
        local e="$(dirname "$f")"
        echo "Reinstalling egg-info in: $e" >&2
        if ! ( cd "$e" && gosu $APP_USER python setup.py egg_info >/dev/null 2>&1; );then
            ( cd "$e" && gosu $APP_USER python setup.py egg_info 2>&1; )
        fi
    fi
}

#  shell: Run interactive shell inside container
_shell() {
    exec gosu ${user:-$APP_USER} $SHELL_EXECUTABLE -$([[ -n ${SSDEBUG:-$SDEBUG} ]] && echo "x" )elc "export PATH=$PATH;${@:-${SHELL_EXECUTABLE}}"
}

#  configure: generate configs from template at runtime
configure() {
    if [[ -n ${NO_CONFIGURE-} ]];then return 0;fi
    for i in $USER_DIRS;do
        if [ ! -e "$i" ];then mkdir -p "$i" >&2;fi
        chown $APP_USER:$APP_GROUP "$i"
    done
    for i in $HISTFILE $MYSQL_HISTFILE $PSQL_HISTORY;do if [ ! -e "$i" ];then touch "$i";fi;done
    for i in $IPYTHONDIR;do if [ ! -e "$i" ];then mkdir -pv "$i";fi;done
    for i in $HISTFILE $MYSQL_HISTFILE $PSQL_HISTORY $IPYTHONDIR;do chown -Rf $APP_USER "$i";done
    if (find /etc/sudoers* -type f >/dev/null 2>&1);then chown -Rf root:root /etc/sudoers*;fi
    # regenerate any setup.py found as it can be an egg mounted from a docker volume
    # without having a chance to be built
    if [[ -z "${SKIP_REGEN_EGG_INFO-}" ]];then
        while read f;do regen_egg_info "$f";done < <( \
            find "$TOPDIR/setup.py" "$TOPDIR/src" "$TOPDIR/sources" \
            -maxdepth 2 -mindepth 0 -name setup.py -type f 2>/dev/null; )
    fi
    # In dev, regenerate mx_dev checkouts
    if [ -e sources/devmode ];then
        chown -Rf $APP_USER $BASE_DIR/sources
        vv gosu $APP_USER mxdev -c mx.ini -v --only-fetch
    fi
    # copy only if not existing template configs from common deploy project
    # and only if we have that common deploy project inside the image
    # we first  create missing structure, but do not override yet (no clobber)
    # then override files if they have no pretendants in project customizations
    if [ ! -e init/etc ];then mkdir -pv init/etc;fi
    for j in etc scripts;do
        for i in local/*deploy-common/$j local/*deploy-common/sys/$j sys/$j;do
            if [ -d $i ];then
                if [ ! -e init/$j ];then mkdir -pv init/$j;fi
                cp -rf${VCOMMAND} $i/. init/$j
                while read conffile;do
                    if [ ! -e sys/$j/$conffile ];then
                        cp -f${VCOMMAND} $i/$conffile init/$j/$conffile
                    fi
                done < <(cd $i && find -type f|sed -re "s/\.\///g")
            fi
        done
    done
    # install with frep any template file to / (eg: logrotate & cron file)
    cd init
    for i in $(find etc -name "*.frep" -type f |grep -E -v "${SKIP_RENDERED_CONFIGS}" 2>/dev/null);do
        d="$(dirname "$i")/$(basename "$i" .frep)"
        di="/$(dirname $d)"
        if [ ! -e "$di" ];then mkdir -p${VCOMMAND} "$di" >&2;fi
        debuglog "Generating with frep $i:/$d"
        frep "$i:/$d" --overwrite
    done
    cd - >/dev/null 2>&1
    write_inituser
    if [ -e etc/zope.ini ];then
        debuglog "Patching zope.ini/max_request_body_size: $MAX_REQUEST_BODY_SIZE"
        sed -i -re "s/(max_request_body_size = ).*/\1$MAX_REQUEST_BODY_SIZE/g"  etc/zope.ini
    fi
}

#  services_setup: when image run in daemon mode: pre start setup like database migrations, etc
services_setup() {
    if [[ -z $NO_IMAGE_SETUP ]];then
        if [[ -n $FORCE_IMAGE_SETUP ]] || ( echo $IMAGE_MODE | grep -E -q "$IMAGE_SETUP_MODES" ) ;then
            debuglog "Force services_setup"
        else
            debuglog "No image setup" && return 0
        fi
    else
        if [[ -n $SKIP_SERVICES_SETUP ]];then
            debuglog "Skip image setup"
            return 0
        fi
    fi
    if [[ "$SKIP_IMAGE_SETUP" = "1" ]];then
        debuglog "Skip image setup" && return 0
    fi
    debuglog "doing services_setup"
    # alpine linux has /etc/crontabs/ and ubuntu based vixie has /etc/cron.d/
    if [ -e /etc/cron.d ] && [ -e /etc/crontabs ];then cp -f$VCOMMAND /etc/crontabs/* /etc/cron.d >&2;fi

    # Run any migration
    if [[ -z ${NO_MIGRATE} ]];then
        ( cd $SRC_DIR && gosu $APP_USER echo migrate; )
    fi
    # Compile gettext messages
    if [[ -z ${NO_COMPILE_MESSAGES} ]];then
        ( compile_messages; )
    fi
    # Collect statics
    if [[ -z ${NO_COLLECT_STATIC} ]];then
        ( cd $SRC_DIR && gosu $APP_USER echo refresh statics; )
    fi
}

# fixperms: basic file & ownership enforcement
fixperms() {
    if [[ -n $NO_FIXPERMS ]];then return 0;fi
    for i in sys/ssh;do
        for j in root ${APP_USER};do
            h=$(eval echo ~$j)
            s=$h/.ssh
            if [ ! -e $s ];then mkdir -pv $s;fi
            if [ -e $i ];then cp -rfv $i/. $s;fi
            chmod -R 0700 $s;chown -R $j $s;chown $j $h;while read f;do chmod 0600 "$f";done < <(find $s -type f)
        done
    done
    if [ "$(id -u $APP_USER)" != "$HOST_USER_UID" ];then
        groupmod -g $HOST_USER_UID $APP_USER
        usermod -u $HOST_USER_UID -g $HOST_USER_UID $APP_USER
    fi
    for i in /etc/{crontabs,cron.d} /etc/logrotate.d /etc/supervisor.d;do
        if [ -e $i ];then
            while read f;do
                chown -R root:root "$f"
                chmod 0640 "$f"
            done < <(find "$i" -type f)
        fi
    done
    for i in $USER_DIRS;do if [ -e "$i" ];then chown $APP_USER:$APP_GROUP "$i";fi;done
    chmod 2755 $BASE_DIR
    while read f;do chmod 0755 "$f"&done < \
        <(find $FINDPERMS_PERMS_DIRS_CANDIDATES -type d -not \( -perm 0755 2>/dev/null \) |sort)
    while read f;do chmod 0644 "$f"&done < \
        <(find $FINDPERMS_PERMS_DIRS_CANDIDATES -type f -not \( -perm 0644 2>/dev/null \) |sort)
    while read f;do chown $APP_USER:$APP_USER "$f"&done < \
        <(find $FINDPERMS_OWNERSHIP_DIRS_CANDIDATES \
          \( -type d -or -type f \) -not \( -user $APP_USER -or -group $APP_GROUP \) 2>/dev/null|sort)
    # plone specific: do not go totally down in data folders for performance !
    while read f;do chown -v ${APP_USER}:${APP_GROUP} "$f"&done < \
        <(find /data -not -user ${APP_USER} -maxdepth 2)
    # end: plone specific
    wait
}

#  usage: print this help
usage() {
    drun="docker run --rm -it <img>"
    echo "EX:
$drun [-e NO_COLLECT_STATIC=1] [-e NO_MIGRATE=1] [ -e FORCE_IMAGE_SETUP] [-e IMAGE_MODE=\$mode]
    docker run <img>
        run either plone, cron, or celery beat|worker daemon
        (IMAGE_MODE: $IMAGE_MODES)

$drun \$args: run commands with the context ignited inside the container
$drun [ -e FORCE_IMAGE_SETUP=1] [ -e NO_IMAGE_SETUP=1] [-e SHELL_USER=\$ANOTHERUSER] [-e IMAGE_MODE=\$mode] [\$command[ \args]]
    docker run <img> \$COMMAND \$ARGS -> run command
    docker run <img> shell -> interactive shell
(default user: $SHELL_USER)
(default mode: $IMAGE_MODE)

If FORCE_IMAGE_SETUP is set: run migrate/collect static
If NO_IMAGE_SETUP is set: migrate/collect static is skipped, no matter what
If NO_START is set: start an infinite loop doing nothing (for dummy containers in dev)
"
  exit 0
}

write_inituser() {
    if [[ -n ${NO_INITUSER-} ]];then return 0;fi
    if [[ -n \"$PLONE_ADMIN_PASSWORD\" ]];then
        python -c "from Zope2.utilities.mkwsgiinstance import write_inituser;\
            write_inituser('inituser', 'admin', '$PLONE_ADMIN_PASSWORD')"
    fi
}

do_fg() {
    write_inituser
    gosu $APP_USER bash -c "set -ex\
    && export TYPE=$PLONE_TYPE SITE=$PLONE_SITE PROFILES=$PLONE_PROFILES \
    && exec ./docker-entrypoint.sh start"
}

execute_hooks() {
    local step="$1"
    local hdir="$INIT_HOOKS_DIR/${step}"
    shift
    if [ ! -d "$hdir" ];then return 0;fi
    while read f;do
        if ( echo "$f" | grep -E -q "\.sh$" );then
            debuglog "running shell hook($step): $f" && . "${f}"
        else
            debuglog "running executable hook($step): $f" && "$f" "$@"
        fi
    done < <(find "$hdir" -type f -executable 2>/dev/null | grep -E -iv readme | sort -V; )
}

# Run app preflight routines (layout, files sync to campanion volumes, migrations, permissions fix, etc.)
pre() {
    if [ "x${NO_PRE_STARTUP-}" != "x" ];then return 0;fi
    if [ -e "${BASE_DIR}/docs" ] && [[ -z "${SKIP_SYNC_DOCS}" ]];then
        rsync -az${VCOMMAND} "${BASE_DIR}/docs/" "${BASE_DIR}/outdocs/" --delete
    fi
    # wait for db to be avalaible (skippable with SKIP_STARTUP_DB)
    # come from https://github.com/corpusops/docker-images/blob/master/rootfs/bin/project_dbsetup.sh
    if [ "x$SKIP_STARTUP_DB" = "x" ];then project_dbsetup.sh;fi
    execute_hooks pre "$@"
    configure
    execute_hooks afterconfigure "$@"
    # fixperms may have to be done on first run
    if ! ( services_setup );then
        fixperms
        execute_hooks beforeservicessetup "$@"
        services_setup
    fi
    execute_hooks afterservicessetup "$@"
    fixperms
    execute_hooks afterfixperms "$@"
    execute_hooks post "$@"
}

compile_messages() {
    local c=$(pwd)/bin/compile_mo.py
    if [ -e /compile_mo.py ];then cp /compile_mo.py bin;fi
    # refresh po's from pot
    if [[ -n ${UPDATE_POT-} ]] && [ -e update_dist_locale ];then update_dist_locale;fi
    # patch compile_messages to also build local pots
    sed -i -re "s:/var/log:/data/logs:" $c
    if ! (grep -q "itertools" $c );then sed -i -re "s/(import os)/import itertools;import os/g" $c;fi
    if ! (grep -q "Path('src').resolve" $c );then sed -i -re "s/ (lib_path\.glob.*)$/ itertools.chain(\1,Path('src').resolve().glob('**\/*.po'),Path('sources').resolve().glob('**\/*.po'))/g" $c;fi
    # compiles messages
    python $c
}

if ( echo $1 | grep -E -q -- "--help|-h|help" );then set -- usage $@;fi
if [[ -n ${NO_START-} ]];then
    while true;do echo "start skipped" >&2;sleep 65535;done
    exit $?
fi
if ( echo $1 | grep -E -q -- "^(${EP_CUSTOM_ACTIONS}do_fg|usage)$" );then $@;exit $?;fi
# export back the gateway ip as a host if ip is available in container
if ( ip -4 route list match 0/0 &>/dev/null );then
    if ! (ip -4 route list match 0/0 | awk '{print $3" host.docker.internal"}' >> /etc/hosts );then echo "failed to patch /etc/hosts, continuing anyway";fi
fi

# only display startup logs when we start in daemon mode and try to hide most when starting an (eventually interactive) shell.
if ! ( echo "$NO_STARTUP_LOGS" | grep -E -iq "^(no?)?$" );then if ! ( pre >"$STARTUP_LOG" 2>&1 );then cat "$STARTUP_LOG">&2;die "preflight startup failed";fi;else pre;fi;

if [[ $IMAGE_MODE == "pycharm" ]];then
    cmdargs="$@"
    for i in ${PYCHARM_DIRS};do if [ -e "$i" ];then chown -Rf $APP_USER "$i";fi;done
    exec gosu $APP_USER bash -lc "set -e;cd $ODIR;export PYTHONPATH=\"$OPYPATH:\${PYTHONPATH-}·\";python $cmdargs"
fi


if [[ "${IMAGE_MODE}" != "shell" ]]; then
    if ! ( echo $IMAGE_MODE | grep -E -q "$IMAGE_MODES" );then die "Unknown image mode ($IMAGE_MODES): $IMAGE_MODE";fi
    log "Running in $IMAGE_MODE mode"
    if [ -e "$STARTUP_LOG" ];then cat "$STARTUP_LOG";fi
    if [[ "$IMAGE_MODE" = "fg" ]]; then
        ( SUPERVISORD_CONFIGS="rsyslog" exec supervisord.sh )&
        do_fg
    else
        # we have two types of CRONTABS, one dedicated to backup and one to application
        rm -fv $(find  /etc/*cron* -name "*plone*" |grep    backup|xargs rm -rfv)
        cfg="/etc/supervisor.d/$IMAGE_MODE"
        if [ ! -e $cfg ];then die "Missing: $cfg";fi
        SUPERVISORD_CONFIGS="rsyslog $cfg" exec supervisord.sh
    fi
else
    if [[ "${1-}" = "shell" ]];then shift;fi
    # retrocompat with old images
    cmd="${@:-bash}"
    if ( echo "$cmd" | grep -E -q "tox.*/bin/sh -c tests" );then
        cmd=$( echo "${cmd}"|sed -r -e "s/-c tests/-exc '.\/manage.py test/" -e "s/$/'/g" )
    fi
    execute_hooks beforeshell "$@"
    ( cd $BASE_DIR && user=$SHELL_USER _shell "$BASE_DIR/docker-entrypoint.sh $cmd" )
fi
# vim:set et sts=4 ts=4 tw=0:
