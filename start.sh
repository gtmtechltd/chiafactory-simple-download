#!/bin/bash

DOWNLOAD_DIR=***
FINAL_DIR=***

if [ -z "${PLOTORDER_API_KEY}" ];then
  echo "Please set PLOTORDER_API_KEY. Ask support@chiafactory.com for one if you dont have one." >&2
  exit 1
fi

set -e -x

while true; do 

  echo "Retrieving current plots"
  PLOTS="$( curl --silent -X GET \
    'https://chiafactory.com/api/v1/plot_orders/' \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "Authorization: Token ${PLOTORDER_API_KEY}" )"

  echo "${PLOTS}" | jq -r .
  FIRST_PLOT="$( echo "${PLOTS}" | jq -r '[.results[] | select( .status == "R" ) | .plots[] | select( .state == "D" )] | first' )"
  PLOT_ID="$( echo "${FIRST_PLOT}" | jq -r .id )"
  DOWNLOAD_URL="$( echo "${FIRST_PLOT}" | jq -r .url )"

  DOWNLOAD_FILE="$( basename "${DOWNLOAD_URL}" )"
  if [ -f "${FINAL_DIR}/${DOWNLOAD_FILE}" ];then
    echo "Not downloading already-existing plot ${PLOT_ID} : ${DOWNLOAD_URL}"
  else
    echo "Downloading plot ${PLOT_ID} : ${DOWNLOAD_URL}"
    (cd "${DOWNLOAD_DIR}" && wget -r --tries=10 "${DOWNLOAD_URL}" -O "${DOWNLOAD_FILE}")
    echo "Moving plot into ${FINAL_DIR}"
    mv "${DOWNLOAD_DIR}/${DOWNLOAD_FILE}" "${FINAL_DIR}/"
    echo "${DOWNLOAD_FILE} downloaded"
  fi

  echo "Archiving plot id ${PLOT_ID}"
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

  echo "Deleting plot id ${PLOT_ID}"
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

done
