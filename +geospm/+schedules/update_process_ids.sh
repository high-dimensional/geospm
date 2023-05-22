#!/bin/bash

PROCESS_ID_FILE="$1"
LOG_FILE="$2"
OUTPUT_FILE="${PROCESS_ID_FILE}.tmp"

: > "$OUTPUT_FILE"

COUNT=0

while IFS= read -r PROCESS_SPECIFIER; do
    
    IFS=':' read -r -a PARTS <<< "$PROCESS_SPECIFIER" ; unset IFS
    
    PROCESS_ID="${PARTS[0]}"
    PROCESS_PATH="${PARTS[1]}"
    
    if ps -p "$PROCESS_ID" > /dev/null ; then
        echo "${PROCESS_ID}:${PROCESS_PATH}" >> "$OUTPUT_FILE"
        COUNT=$(( $COUNT + 1 ))
    elif [[ "$LOG_FILE" != "" ]] ; then
        echo "$PROCESS_PATH" >> "$LOG_FILE"
    fi
    
done < "$PROCESS_ID_FILE"

cat "$OUTPUT_FILE" > "$PROCESS_ID_FILE"
rm "$OUTPUT_FILE"

echo "$COUNT"
