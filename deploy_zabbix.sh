#!/usr/bin/env ksh
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

BIND_URL=${1:-http://localhost:8653/xml}

mkdir -p ${ZABBIX_DIR}/scripts/agentd/bindix
cp -rv ${SOURCE_DIR}/bindix/bindix.conf.example   ${ZABBIX_DIR}/scripts/agentd/bindix/bindix.conf
cp -rv ${SOURCE_DIR}/bindix/bindix.sh             ${ZABBIX_DIR}/scripts/agentd/bindix/
cp -rv ${SOURCE_DIR}/bindix/zabbix_agentd.conf    ${ZABBIX_DIR}/zabbix_agentd.d/bindix.conf
sed -i "s|BIND_URL=.*|BIND_URL=\"${BIND_URL}\"|g" ${ZABBIX_DIR}/scripts/agentd/bindix/bindix.conf
