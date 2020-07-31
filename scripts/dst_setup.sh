#!/bin/bash

# Exposed args
# server_zip - server zip path

# argparse; see https://stackoverflow.com/a/14203146/4407321

echo_header "DST Server Setup"

POSITIONAL=()
update=true

function print_help {
    echo "usage: dst setup server_zip"
    echo "--help           show this page"
    echo "server_zip       path to server zip"
}

while [[ $# -gt 0 ]]; do
key="$1"

case $key in
    -h|--help)
    echo "Setup DST server"
    print_help
    exit 0
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
    echo "Missing server zip path; see TODO"
    print_help
    exit 1
fi

server_zip="$1"
server_zip="$(abs_path "$server_zip")"

########################################################################

# Read config
# Overrides at config.cfg
# Defaults at config.cfg.defaults

source scripts/read_config.sh;

dst_dir="$(config_get dst_dir)"
dst_dir="$(abs_path "$dst_dir")"

########################################################################

echo "Validating $(basename -- "$server_zip")"

# All DST zip folders are expected to have:
# - MyDediServer root folder
# - cluster.ini file

if [[ "$(zipinfo -1 "$server_zip")" != "MyDediServer/"*"cluster.ini"* ]];
    echo "Zip format mismatch; is this zip file a DST server?"
    exit 1
fi

########################################################################

echo "Extracting $(basename -- "$server_zip")"

dst_temp_dir="$dst_dir/.temp"

if [ -d "$dst_temp_dir/MyDediServer" ]; then 
    echo "Please clear $dst_temp_dir before proceeding"
    exit 1
fi

unzip "$server_zip" -d "$dst_temp_dir"

# Extract server name from ini file
# Server name starts with `cluster_name =`
# Replace all space with underscores
server_name="$(sed -n -e 's/^cluster_name =[[:space:]]*//p' "$dst_temp_dir/MyDediServer/cluster.ini" | sed 's/[[:space:]]/_/')"

if [ -z "$server_name" ]; then 
    echo "Could not find server name"
    exit 1
fi

server_dir="$dst_dir/$server_name"

if [ -d "$server_dir" ]; then 
    echo "$server_dir already exists; aborting"
    exit 1
fi

mv "$dst_temp_dir/MyDediServer" "$server_dir"

rm -r "$dst_temp_dir"

echo "Moved $server_zip to $server_dir"

########################################################################

server_config_dir="$project_dir/servers/$server_name"

if [ -d "$server_config_dir" ]; then
    echo "Server configs already exist at $server_config_dir"
else
    cp -r "$project_dir/servers/_Template" "$server_config_dir"
    echo "Created server configs at $server_config_dir"
fi

echo "Finished setup! Update the configs, or call `dst start $server_name` to start a vanilla server"



