#!/usr/bin/env ksh
PATH=/usr/local/bin:${PATH}
IFS_DEFAULT="${IFS}"
#################################################################################

#################################################################################
#
#  Variable Definition
# ---------------------
#
APP_NAME=$(basename $0)
APP_DIR=$(dirname $0)
APP_VER="0.0.1"
APP_WEB="http://www.sergiotocalini.com.ar/"
TIMESTAMP=`date '+%s'`
CACHE_DIR=${APP_DIR}/tmp
CACHE_TTL=5                                      # IN MINUTES
#
#################################################################################

#################################################################################
#
#  Load Environment
# ------------------
#
[[ -f ${APP_DIR}/${APP_NAME%.*}.conf ]] && . ${APP_DIR}/${APP_NAME%.*}.conf

#
#################################################################################

#################################################################################
#
#  Function Definition
# ---------------------
#
usage() {
    echo "Usage: ${APP_NAME%.*} [Options]"
    echo ""
    echo "Options:"
    echo "  -a            Query arguments."
    echo "  -h            Displays this help message."
    echo "  -j            Jsonify output."
    echo "  -s ARG(str)   Section (default=stat)."
    echo "  -v            Show the script version."
    echo ""
    echo "Please send any bug reports to sergiotocalini@gmail.com"
    exit 1
}

version() {
    echo "${APP_NAME%.*} ${APP_VER}"
    exit 1
}

refresh_cache() {
    [[ -d ${CACHE_DIR} ]] || mkdir -p ${CACHE_DIR}
    file=${CACHE_DIR}/data.cache
    if [[ $(( `stat -c '%Y' "${file}" 2>/dev/null`+60*${CACHE_TTL} )) -le ${TIMESTAMP} ]]; then
    	curl -g -s "${BIND_URL}" 2>/dev/null > ${file}
    fi
    echo "${file}"
}

discovery() {
    resource=${1}

    IFS=${IFS_DEFAULT}
    cache=$(refresh_cache)
    if [[ ${resource} == 'zones' ]]; then
	for view in `xmlstarlet sel -T -t -m /statistics/views/view/@name -v . -n "${cache}"`; do
	    zone_path="/statistics/views/view[@name=\"${view}\"]/zones"
	    path="${zone_path}/zone[serial>0]/@name"
	    for zone in `xmlstarlet sel -T -t -m ${path} -v . -n "${cache}"`; do
		path="${zone_path}/zone[@name=\"${zone}\"]/@rdataclass"
		rdataclass=`xmlstarlet sel -T -t -m ${path} -v . -n "${cache}"`
		echo "${zone}|${rdataclass}|${serial}|${view}"
	    done
	done
    fi
    return 0
}

get_stats_zone() {
    view=${1:-_default}
    zone=${2}
    type=${3}
    name=${4}
    
    cache=$(refresh_cache)
    if [[ -n ${zone} && -n ${type} && -n ${name} ]]; then
	zone_path="/statistics/views/view[@name=\"${view}\"]/zones/zone[@name=\"${zone}\"]"
	attr_path="${zone_path}/counters[@type=\"${type}\"]/counter[@name=\"${name}\"]"
	res=`xmlstarlet sel -T -t -m ${attr_path} -v . -n "${cache}"`
    fi
    echo ${res:-0}
}


get_stats_server() {
    type=${1}
    attr=${2}

    cache=$(refresh_cache)
    if [[ ${type} =~ (boot-time|config-time|current-time) ]]; then
	path="/statistics/server/${type}"
    else
	path="/statistics/server/counters[@type=\"${type}\"]/counter[@name=\"${attr}\"]"
    fi
    res=`xmlstarlet sel -T -t -m ${path} -v . -n "${cache}"`
    echo ${res:-0}
}

get_stats_memory() {
    type=${1}
    attr=${2}

    cache=$(refresh_cache)
    path="/statistics/memory/${type}/${attr}"
    res=`xmlstarlet sel -T -t -m ${path} -v . -n "${cache}"`
    echo ${res:-0}
}

get_service() {
    resource=${1}

    port=`echo "${NGINX_URL}" | sed -e 's|.*://||g' -e 's|/||g' | awk -F: '{print $2}'`
    pid=`sudo lsof -Pi :${port:-80} -sTCP:LISTEN -t | head -1`
    rcode="${?}"
    if [[ ${resource} == 'listen' ]]; then
	if [[ ${rcode} == 0 ]]; then
	    res=1
	fi
    elif [[ ${resource} == 'uptime' ]]; then
	if [[ ${rcode} == 0 ]]; then
	    res=`sudo ps -p ${pid} -o etimes -h`
	fi
    fi
    echo ${res:-0}
    return 0
}

#
#################################################################################

#################################################################################
while getopts "s::a:s:uphvj:" OPTION; do
    case ${OPTION} in
	h)
	    usage
	    ;;
	s)
	    SECTION="${OPTARG}"
	    ;;
        j)
            JSON=1
            IFS=":" JSON_ATTR=(${OPTARG//p=})
            ;;
	a)
	    ARGS[${#ARGS[*]}]=${OPTARG//p=}
	    ;;
	v)
	    version
	    ;;
         \?)
            exit 1
            ;;
    esac
done

if [[ ${JSON} -eq 1 ]]; then
    rval=$(discovery ${ARGS[*]})
    echo '{'
    echo '   "data":['
    count=1
    while read line; do
        IFS="|" values=(${line})
        output='{ '
        for val_index in ${!values[*]}; do
            output+='"'{#${JSON_ATTR[${val_index}]:-${val_index}}}'":"'${values[${val_index}]}'"'
            if (( ${val_index}+1 < ${#values[*]} )); then
                output="${output}, "
            fi
        done 
        output+=' }'
        if (( ${count} < `echo ${rval}|wc -l` )); then
            output="${output},"
        fi
        echo "      ${output}"
        let "count=count+1"
    done <<< ${rval}
    echo '   ]'
    echo '}'
else
    if [[ ${SECTION} == 'discovery' ]]; then
        rval=$(discovery ${ARGS[*]})
        rcode="${?}"
    elif [[ ${SECTION} == 'service' ]]; then
	rval=$( get_service ${ARGS[*]} )
	rcode="${?}"	
    else
	if [[ ${ARGS[0]} == "zone" ]]; then
	    rval=$(get_stats_zone ${ARGS[*]:1} )
	    rcode="${?}"
	elif [[ ${ARGS[0]} == "server" ]]; then
	    rval=$(get_stats_server ${ARGS[*]:1} )
	    rcode="${?}"
	elif [[ ${ARGS[0]} == "memory" ]]; then
	    rval=$(get_stats_memory ${ARGS[*]:1} )
	    rcode="${?}"	    
	fi
    fi
    echo ${rval:-0} | sed "s/null/0/g"
fi

exit ${rcode}
