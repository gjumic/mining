#!/usr/bin/env bash

export LD_LIBRARY_PATH=/hive/xmr-stak/fireice-uk

cd `dirname $0`

[ -t 1 ] && . colors

. h-manifest.conf
. /hive-config/wallet.conf

[[ -z $CUSTOM_LOG_BASENAME ]] && echo -e "${RED}No CUSTOM_LOG_BASENAME is set${NOCOLOR}" && exit 1
[[ -z $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}No CUSTOM_CONFIG_FILENAME is set${NOCOLOR}" && exit 1
[[ ! -f $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}Custom config ${YELLOW}$CUSTOM_CONFIG_FILENAME${RED} is not found${NOCOLOR}" && exit 1
CUSTOM_LOG_BASEDIR=`dirname "$CUSTOM_LOG_BASENAME"`
[[ ! -d $CUSTOM_LOG_BASEDIR ]] && mkdir -p $CUSTOM_LOG_BASEDIR

#if [[ ${CUSTOM_ALGO} == "cryptonight-lite-v7" || ${CUSTOM_ALGO} == "cryptonight-heavy" ]]; then
#   echo -e "${BCYAN}Cryptonight-lite${NOCOLOR} in ${RED}XMRig-AMD 2.8.2${NOCOLOR} is broken, using ${RED}XMRig-AMD 2.8.1${NOCOLOR} instead"
#   ln -fs xmrig-amd_281 xmrig-amd
#else
#   echo -e "Using ${RED}XMRig-AMD 2.8.2${NOCOLOR}"
#   ln -fs xmrig-amd_282 xmrig-amd
#fi

./xmrig-amd $(< $CUSTOM_NAME.conf) --api-port=$WEB_PORT$ | tee $CUSTOM_LOG_BASENAME.log

