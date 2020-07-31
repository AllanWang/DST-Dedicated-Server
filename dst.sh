#!/bin/bash

########################################################################

# Init

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

cd "$project_dir"

function abs_path {
    path="$1"
    path="${path/#\~/$HOME}"
    # path="$(realpath "$path")" # Not present on mac
    echo "$path"
}

function echo_header {
    echo "-------------------------------------------"
    echo "$1"
}

########################################################################

# Initial arg parse

function print_help {
    echo "DST usage"
    echo "-h|help|--help   print this message"
    echo "start            launch a server"
    echo "setup            create a server"
    echo "pull             pull source code"
}

if [[ $# -lt 1 ]]; then
    echo "Missing starting argument"
    print_help
    exit 1
fi

command="$1"
shift

case $command in
    -h|help|--help)
    print_help
    exit 0
    ;;
    start)
    source scripts/dst_start.sh "$@"
    ;;
    setup)
    source scripts/dst_setup.sh "$@"
    ;;
    pull)
    source scripts/dst_pull.sh "$@"
    ;;
    *)
    echo "Invalid option $command"
    print_help
    exit 1
    ;;
esac