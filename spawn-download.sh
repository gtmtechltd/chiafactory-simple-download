#!/bin/bash

BASEDIR="$( cd "$(dirname "$0" )" && /bin/pwd )"
CONFIG_FILE="${BASEDIR}/config.json"

DOWNLOAD_DIR="$(      jq -r .download_dir      < "${CONFIG_FILE}" )"
FINAL_DIR="$(         jq -r .download_dir      < "${CONFIG_FILE}" )"
PLOTORDER_API_KEY="$( jq -r .plotorder_api_key < "${CONFIG_FILE}" )"
PLOT_ID=$1
DOWNLOAD_URL=$2

log() {
  PREFIX="$( date "+%H:%M:%S" ) [${PLOT_ID}] "
  echo "${PREFIX}$*" >> simple.log
}

abort() {
  trap - EXIT
  log "${PLOT_ID} aborted"
  echo "${PLOT_ID} aborted"
  exit 1
}

trap abort EXIT
set -e

if [ -z "$2" ];then
  log "Usage: $0 <plot-id> <download-url>" >&2
  echo "Usage: $0 <plot-id> <download-url>" >&2
  exit 1
fi

DOWNLOAD_FILE="$( basename "${DOWNLOAD_URL}" )"
if [ -f "${FINAL_DIR}/${DOWNLOAD_FILE}" ];then
  log "* Not downloading already-existing plot ${PLOT_ID} : ${DOWNLOAD_URL}"
else
  log "- Downloading plot ${PLOT_ID} : ${DOWNLOAD_URL}"
  (cd "${DOWNLOAD_DIR}" && wget -r --tries=10 "${DOWNLOAD_URL}" -O "${DOWNLOAD_FILE}")
  log "- Moving plot into ${FINAL_DIR}"
  mv "${DOWNLOAD_DIR}/${DOWNLOAD_FILE}" "${FINAL_DIR}/"
  log "${DOWNLOAD_FILE} downloaded"
fi

log "- Archiving plot id ${PLOT_ID}"
curl --silent -X PUT \
  "https://chiafactory.com/api/v1/plots/${PLOT_ID}/" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Token ${PLOTORDER_API_KEY}" \
  -d "{
    \"id\": \"${PLOT_ID}\",
    \"download_state\": 2
  }" \
  | sed -e 's/^/    /g'

log "- Deleting plot id ${PLOT_ID}"
curl --silent -X PUT \
  "https://chiafactory.com/api/v1/plots/${PLOT_ID}/" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Token ${PLOTORDER_API_KEY}" \
  -d "{
    \"id\": \"${PLOT_ID}\",
    \"state\": \"X\",
    \"download_state\": 3
  }" \
  | sed -e 's/^/    /g'

trap - EXIT
log "Finished"

