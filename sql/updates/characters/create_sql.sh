#!/usr/bin/env bash

CUR_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOLDER_NAME="$(basename "$CUR_PATH")"

if [[ "$(uname)" == 'Darwin' ]]; then
    datecmd='gdate'
else
    datecmd='date'
fi

DATE_STR="$($datecmd +%Y_%m_%d)"

idx=0
while : ; do
    filename="${DATE_STR}_${FOLDER_NAME}_$(printf '%02d' $idx).sql"
    if [[ ! -e "$CUR_PATH/$filename" ]]; then
        break
    fi
    idx=$((idx + 1))
done

echo "--" > "$CUR_PATH/$filename"
echo "File created: $filename"
