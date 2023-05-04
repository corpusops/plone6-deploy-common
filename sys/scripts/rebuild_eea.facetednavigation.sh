#!/usr/bin/env bash
export NODE_VERSION=${NODE_VERSION:-18.16.0}
export BASE_DIR="${BASE_DIR:-$(dirname $(dirname $(dirname $(readlink -f $0))))}"
f="$BASE_DIR/sources/eea.facetednavigation/rebuilt~"
if [ ! -e sources/eea.facetednavigation ];then
    exit 0
fi
if [ -e $f ] && [ -z ${FORCE_REBUILD_EEA} ];then
    echo "eea.facetednavigation already rebuilt (flag: $f">&2
    exit 0
fi
if ! ( which node &>/dev/null );then
    curl https://nodejs.org/dist/v{$NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz | tar xJvf - --strip-components=1 -C /usr/local
    npm install --global yarn
fi
cd sources/eea.facetednavigation
gosu $APP_USER sh -c "yarn install && yarn build"
if [ -e /.dockerenv ];then
    rm -rf node_modules
fi
touch "$f"
# vim:set et sts=4 ts=4 tw=80:
