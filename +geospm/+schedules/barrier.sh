#!/bin/bash

WAIT_PERIOD=60
PROCESS_ID_FILE=
LOG_FILE=

function where_am_i() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
      local dir="$( cd -P "$( dirname "$source" )" && pwd )"

      source="$(readlink "$source")"
      [[ $source != /* ]] && source="$dir/$source"
    done
    local dir="$( cd -P "$( dirname "$source" )" && pwd )"
    IFS= read -r "$1" <<<"$dir"
}

script_directory="$(pwd)"
where_am_i "script_directory"

update_process_ids="${script_directory}/update_process_ids.sh"

function usage() {
    local indent="   "
    echo "Usage: barrier [...]"
    
    echo "${indent}Monitors the provided list of process ids."
    
    echo "${indent}Options/Arguments:"
                
    echo "${indent}{-p, --process-id-file} Path of file with process ids."
    echo "${indent}{-l, --log-file} Path of file to hold paths of completed processes."
}

while [ "$1" != "" ]; do

    case $1 in
        -h | --help )           usage
                                exit
                                ;;
        -w | --wait-period ) shift
                                if [ "$#" -eq 0 ]; then
                                    echo "${indent}Missing --wait-period argument."; exit 1
                                fi
                                WAIT_PERIOD="$1"
                                ;;
        -p | --process-id-file ) shift
                                if [ "$#" -eq 0 ]; then
                                    echo "${indent}Missing --process-id-file argument."; exit 1
                                fi
                                PROCESS_ID_FILE="$1"
                                ;;
        -l | --log-file ) shift
                                if [ "$#" -eq 0 ]; then
                                    echo "${indent}Missing --log-file argument."; exit 1
                                fi
                                LOG_FILE="$1"
                                ;;
        * )                     if [[ "$1" =~ -.* ]]; then
                                    echo "${indent}Unknown option: $1"; exit 1
                                fi
                                
                                if [ "$#" -ne 0 ]; then
                                    echo "Unexpected arguments: $@"; exit 1
                                fi
                                
                                break
    esac
    shift
done

echo "Barrier Started"

while true ; do
    
    N_ACTIVE=$( "$update_process_ids" "$PROCESS_ID_FILE" "$LOG_FILE" )
    
    if [[ "$N_ACTIVE" -eq 0 ]]; then
        break
    fi
    
    echo "Barrier: $N_ACTIVE active processes, sleeping for $WAIT_PERIOD seconds..."
    
    sleep "$WAIT_PERIOD"
done

echo "Barrier Done"

# Poll for file events, timeout every x minutes to see which processes are still running

# inotifywait -m "${target_directory}" -e close_write -e moved_to -t 300 |
#    while read path action file; do
#
#        echo "The file '$file' appeared in directory '$path' via '$action'"
#
#        if [[ "$file" != *.completed ]]; then
#            continue
#        fi
#
#    done
