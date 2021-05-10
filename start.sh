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

  FIRST_PLOT="$( echo "${PLOTS}" | jq -r '[.results[] | select( .status == "R" ) | .plots[] | select( .state == "D" )] | first' )"
  PLOT_ID="$( echo "${FIRST_PLOT}" | jq -r .id )"
  DOWNLOAD_URL="$( echo "${FIRST_PLOT}" | jq -r .url )"

  echo "Downloading plot ${PLOT_ID} : ${DOWNLOAD_URL}"
  (cd "${DOWNLOAD_DIR}" && wget -r --tries=10 "${DOWNLOAD_URL}")

  PLOT_FILE="$( echo "${DOWNLOAD_URL}" | sed -e 's/.*\///g' )"

  echo "Moving plot into ${FINAL_DIR}"
  mv "${PLOT_FILE}" "${FINAL_DIR}/"

  echo "${PLOT_FILE} downloaded"
  read -r -p "Downloaded... press enter to continue" VAR

  sleep 600

  echo "Archiving plot id ${PLOT_ID}"
  curl --silent -X PUT \
    "https://chiafactory.com/api/v1/plots/${PLOT_ID}" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "Authorization: Token ${PLOTORDER_API_KEY}" \
    -d "{
      \"id\": \"${PLOT_ID}\",
      \"state\": \"R\"
    }" \
  | sed -e 's/^/    /g'

  echo "Deleting plot id ${PLOT_ID}"
  curl --silent -X DELETE \
    "https://chiafactory.com/api/v1/plots/${PLOT_ID}" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "Authorization: Token ${PLOTORDER_API_KEY}" \
  | sed -e 's/^/    /g'

done
