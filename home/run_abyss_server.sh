#!/bin/bash

install_dir="$HOME/server_dst"
cluster_name="Abyss"
dontstarve_dir="$HOME/.klei/DoNotStarveTogether"

function fail()
{
	echo Error: "$@" >&2
	exit 1
}

function check_for_file()
{
	if [ ! -e "$1" ]; then
		fail "Missing file: $1"
	fi
}

function copy_file()
{
	if [ -f "$1" ]; then 
		cp "$1" "$2"
		echo "Copied $1"
	fi 
}

check_for_file "$dontstarve_dir/$cluster_name/cluster.ini"
check_for_file "$dontstarve_dir/$cluster_name/cluster_token.txt"
check_for_file "$dontstarve_dir/$cluster_name/Master/server.ini"
check_for_file "$dontstarve_dir/$cluster_name/Caves/server.ini"

check_for_file "$install_dir/bin"

copy_file "$cluster_name/modoverrides.lua" "$dontstarve_dir/$cluster_name/Master/modoverrides.lua"
copy_file "$cluster_name/modoverrides.lua" "$dontstarve_dir/$cluster_name/Caves/modoverrides.lua"
copy_file "$cluster_name/dedicated_server_mods_setup.lua" "$install_dir/mods/dedicated_server_mods_setup.lua"
copy_file "$cluster_name/worldgenoverride.lua" "$dontstarve_dir/$cluster_name/Master/worldgenoverride.lua"

cd "$install_dir/bin" || fail

run_shared=(./dontstarve_dedicated_server_nullrenderer)
run_shared+=(-console)
run_shared+=(-cluster "$cluster_name")
run_shared+=(-monitor_parent_process $$)

"${run_shared[@]}" -shard Caves  | sed 's/^/Caves:  /' &
"${run_shared[@]}" -shard Master | sed 's/^/Master: /'