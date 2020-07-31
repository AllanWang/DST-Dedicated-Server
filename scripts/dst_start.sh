#!/bin/bash

# Exposed args
# update - true if steam update should be called
# server - server name

# argparse; see https://stackoverflow.com/a/14203146/4407321

POSITIONAL=()
update=true

function print_help {
    echo "usage: dst start [--no-update] [--help] server"
    echo "--no-update  disable steam update"
    echo "--help       show this page"
    echo "server       name of the server"
}

while [[ $# -gt 0 ]]; do
key="$1"

case $key in
    -h|--help)
    echo "Start DST server"
    print_help
    exit 0
    ;;
    --no-update)
    update=false
    shift
    ;;
    -*)    # unknown option
    echo "Invalid option $1"
    print_help
    exit 1
    ;;
    *)
    POSITIONAL+=("$1") 
    shift
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ $# -ne 1 ]]; then
    echo "Missing server name"
    print_help
    exit 1
fi

server="$1"

server_config_dir="$project_dir/servers/$server"

########################################################################

# Read config
# Overrides at config.cfg
# Defaults at config.cfg.defaults

source scripts/read_config.sh;

install_dir="$(config_get install_dir)"
install_dir="$(abs_path "$install_dir")"

echo "$install_dir"
dst_dir="$(config_get dst_dir)"
dst_dir="${dst_dir/#\~/$HOME}"

server_dir="$dst_dir/$server"

########################################################################

# Utils

function echo_header {
    echo "-------------------------------------------"
    echo "$1"
}

########################################################################

echo_header "Validating $server"

function check_for_file {
	if [ ! -e "$1" ]; then
		echo "Missing file: $1"
        exit 1
	fi
}

check_for_file "$server_config_dir"
check_for_file "$server_dir/cluster.ini"
check_for_file "$server_dir/cluster_token.txt"
check_for_file "$server_dir/Master/server.ini"
check_for_file "$server_dir/Caves/server.ini"

check_for_file "$install_dir/bin"

########################################################################

if [ "$update" = "true" ]; then
    echo_header "Updating steam"
    steamcmd +force_install_dir "$install_dir" +login anonymous +app_update 343050 validate +quit
else
    echo_header "Skipping steam update"
fi

########################################################################

echo_header "Updating configs"

function copy_file {
	if [ -f "$1" ]; then 
		cp "$1" "$2"
		echo "Copied $1"
	fi 
}

copy_file "$server_config_dir/modoverrides.lua" "$server_dir/Master/modoverrides.lua"
copy_file "$server_config_dir/modoverrides.lua" "$server_dir/Caves/modoverrides.lua"
copy_file "$server_config_dir/dedicated_server_mods_setup.lua" "$install_dir/mods/dedicated_server_mods_setup.lua"
copy_file "$server_config_dir/worldgenoverride.lua" "$server_dir/Master/worldgenoverride.lua"

########################################################################

echo_header "Starting $server"

cd "$install_dir/bin" || exit 1

run_shared=(./dontstarve_dedicated_server_nullrenderer)
run_shared+=(-console)
run_shared+=(-cluster "$server")
run_shared+=(-monitor_parent_process $$)

"${run_shared[@]}" -shard Caves  | sed 's/^/Caves:  /' &
"${run_shared[@]}" -shard Master | sed 's/^/Master: /'
