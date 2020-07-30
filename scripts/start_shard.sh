#!/bin/bash

# For reasons unknown, this section can not be converted to run in a python subprocess
# We will instead pass arguments over and call it in the script

cluster_name="$1"
shard="$2"
pid="$3"

run_shared=(./dontstarve_dedicated_server_nullrenderer)
run_shared+=(-console)
run_shared+=(-cluster "$cluster_name")
run_shared+=(-monitor_parent_process "$pid"

"${run_shared[@]}" -shard "$shard" | sed "s/^/$shard:  /"