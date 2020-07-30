#!/bin/bash

########################################################################

# Init

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"


########################################################################

# Exposed args
# update - true if steam update should be called
# server - server name

source scripts/read_args.shlib

server_config_dir="$project_dir/home/$server"

########################################################################

# Read config
# Overrides at config.cfg
# Defaults at config.cfg.defaults

source scripts/read_config.shlib;

install_dir="$(realpath $(config_get install_dir))"
dst_dir="$(realpath $(config_get dst_dir))"
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
