#!/bin/bash -e

BASEDIR="$( cd "$(dirname "$0" )" && /bin/pwd )"

MAX_CONCURRENT_DOWNLOADS="$( jq -r .max_concurrent_downloads < "${BASEDIR}/config.json" )"
PLOTORDER_API_KEY="$(        jq -r .plotorder_api_key        < "${BASEDIR}/config.json" )"

if [ -z "${PLOTORDER_API_KEY}" ];then
  echo "Please set PLOTORDER_API_KEY. Ask support@chiafactory.com for one if you dont have one." >&2
  exit 1
fi

log() {
  PREFIX="$( date "+%H:%M:%S" ) [main] "
  echo "${PREFIX}$*" >&2
  echo "${PREFIX}$*" >> simple.log
}

while true; do 
  log "Retrieving current plots"
  FIRST_PLOT=""

  # shellcheck disable=SC2009
  ACTIVE_DOWNLOADS="$( ps auxww | grep wget | grep plot | sed -e 's/.* //' )"
  NUM_ACTIVE_DOWNLOADS="$( echo "${ACTIVE_DOWNLOADS}" | wc -l | sed -e 's/^ *//' )"
  if [ "${NUM_ACTIVE_DOWNLOADS}" -ge "${MAX_CONCURRENT_DOWNLOADS}" ];then
    log "Number of active downloads (${NUM_ACTIVE_DOWNLOADS}) >= max allowed concurrent downloads (${MAX_CONCURRENT_DOWNLOADS}) - Sleeping for 20s"
    sleep 20
    continue
  fi

  log "Number of active downloads (${NUM_ACTIVE_DOWNLOADS}) < max allowed concurrent downloads (${MAX_CONCURRENT_DOWNLOADS}) - Spawning new download"

  unset PLOT_ID DOWNLOAD_URL
  while true; do
    PLOTS="$( curl --silent -X GET \
      'https://chiafactory.com/api/v1/plot_orders/' \
      -H 'accept: application/json' \
      -H 'Content-Type: application/json' \
      -H "Authorization: Token ${PLOTORDER_API_KEY}" )"

    echo "${PLOTS}" | jq -r . >> simple.log
    ALL_DOWNLOADABLE_PLOTS="$( echo "${PLOTS}" | jq -r '[.results[] | select( .status == "R" ) | .plots[] | select( .state == "D" )]' )"
    # shellcheck disable=SC2034
    PLOT1="$( echo "${ALL_DOWNLOADABLE_PLOTS}" | jq -r '.[0]' )"
    # shellcheck disable=SC2034
    PLOT2="$( echo "${ALL_DOWNLOADABLE_PLOTS}" | jq -r '.[1]' )"
    # shellcheck disable=SC2034
    PLOT3="$( echo "${ALL_DOWNLOADABLE_PLOTS}" | jq -r '.[2]' )"   # plotorder does not give you more than 3 possible plots
    unset NEW_PLOT
    for i in 1 2 3 ; do
      log "- available plots(${i}):"
      PLOT_CANDIDATE="PLOT${i}"
      PLOT_VALUE="$( echo "${!PLOT_CANDIDATE}" | jq -r .url )"
      log "  - url: ${PLOT_VALUE}"
      PLOT_FILE="$( basename "${PLOT_VALUE}" )"
      log "  - filename: ${PLOT_FILE}"
      if [ "${PLOT_FILE}" == "" ] || [ "${PLOT_FILE}" == "null" ];then
        log "    - plotfile is null - ignoring"
        continue
      fi
      if echo "${ACTIVE_DOWNLOADS}" | grep -q -F "${PLOT_FILE}" ; then
        log "    - plotfile is already being downloaded by another process - ignoring"
        continue
      fi
      log "    - plotfile is new. Selecting for download"
      NEW_PLOT="${!PLOT_CANDIDATE}"
      break
    done
    
    DOWNLOAD_URL="$( echo "${NEW_PLOT}" | jq -r .url )"
    PLOT_ID="$( echo "${NEW_PLOT}" | jq -r .id )"
    if [ "${PLOT_ID}" == "" ] || [ "${PLOT_ID}" == "null" ];then
      log "- Waiting for new plot to become available for download. - Sleeping for 60s"
      sleep 60
      continue
    else
      log "- Found plot id ${PLOT_ID} with url ${DOWNLOAD_URL}"
      break
    fi
  done

  log "Spawning plot download"
  
  (set -x ;
   "${BASEDIR}/spawn-download.sh" "${PLOT_ID}" "${DOWNLOAD_URL}" >/dev/null & )

  log "- Done. Sleeping 20 seconds"
  sleep 20
done
