#!/bin/bash

install_dir="$HOME/server_dst"

steamcmd +force_install_dir "$install_dir" +login anonymous +app_update 343050 validate +quit
