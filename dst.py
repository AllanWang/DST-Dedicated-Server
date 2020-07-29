import argparse
import subprocess
import configparser
import os
from os.path import join
import shutil

BASE_DIR = os.path.dirname(os.path.realpath(__file__))

def project_dir(relative: str) -> str:
    return join(BASE_DIR, relative)

def header_print(text: str):
    print("-----------------------------------------")
    print(text, end='\n\n\n')

header_print('Verifying configs')

# Read args
parser = argparse.ArgumentParser(description='Launch DST Server')
parser.add_argument('server', metavar='F', type=str,
                    help='server folder name')
parser.add_argument('--no-update', dest='no_update', action='store_const',
                    const=True, default=False,
                    help='skip server update (default: false)')

args = parser.parse_args()
server = args.server
server_dir = project_dir(server)

if not os.path.isdir(server_dir):
    raise ValueError(f"{server_dir} does not point to a valid folder")

# Read config.ini

config = configparser.ConfigParser()
config.read('config.ini')

def config_dir(key: str) -> str:
    value = config.get('Paths', key)
    dir = os.path.expanduser(value)
    if not os.path.isdir(dir):
        raise ValueError(f"Invalid path provided in config ([Paths] {key} = {value})")
    return dir


install_dir = config_dir('install_dir')
install_bin = join(install_dir, 'bin')

if not os.path.isdir(install_bin):
    raise ValueError(f"Invalid install_dir {install_dir}")

dst_dir = config_dir('dst_dir')

cluster_dir = join(install_dir, server)

def check_cluster_file(relative: str):
    dir = join(cluster_dir, relative)
    if not os.path.isdir(dir):
        raise ValueError(f"Invalid cluster folder {cluster_dir}; please follow server setup (TODO link)")

check_cluster_file('cluster.ini')
check_cluster_file('cluster_token.txt')
check_cluster_file('Master/server.ini')
check_cluster_file('Caves/server.ini')

header_print(f"Setting up {server}")

def copy_config_file(source_relative: str, dest_file: str):
    source_file = join(server_dir, source_relative)
    if os.path.isfile(source_file):
        print(f"Copied {source_relative}")
        shutil.move(source_file, dest_file)

# Master configs
for f in ['modoverrides.lua', 'worldgenoverride.lua']:
    copy_config_file(f, join(cluster_dir, 'Master', f))

# Cave configs
for f in ['modoverrides.lua']:
    copy_config_file(f, join(cluster_dir, 'Caves', f))

# Mod configs
for f in ['dedicated_server_mods_setup.lua']:
    copy_config_file(f, join(install_dir, 'mods', f))

# Run script    

if not args.no_update:
    header_print(f"Updating {dst_dir}")
    subprocess.run(['steamcmd', '+force_install_dir', install_dir, '+login', 'anonymous', '+app_update', '343050', 'validate', '+quit'])
    
header_print(f"Starting {server}")

try:
    os.chdir(install_bin)
except OSError:
    raise ValueError(f"Could not change to bin directory {install_bin}")

base_run = ['./dontstarve_dedicated_server_nullrenderer', '-console', f"-cluster {server}", f"-monitor_parent_process {os.getpid()}"]

def async_run(shard: str):
    print(f"Starting shard {shard}")
    run_commands = base_run + [f"-shared {shard}"]
    ps = subprocess.Popen(run_commands, stdout=subprocess.PIPE)
    subprocess.check_output(['sed', f"s/^/{shard}:  /"], stdin=ps.stdout)

async_run('Caves')
async_run('Master')
