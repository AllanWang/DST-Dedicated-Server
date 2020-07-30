import argparse
import subprocess
import configparser
import os
from os.path import join
import shutil
import asyncio

BASE_DIR = os.path.dirname(os.path.realpath(__file__))


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
server_dir = join(BASE_DIR, 'home', server)

if not os.path.isdir(server_dir):
    raise ValueError(f"{server_dir} does not point to a valid folder")

# Read config.ini

config = configparser.ConfigParser()
config.read('config.ini')


def config_dir(key: str) -> str:
    value = config.get('Paths', key)
    dir = os.path.expanduser(value)
    if not os.path.isdir(dir):
        raise ValueError(
            f"Invalid path provided in config ([Paths] {key} = {value})")
    return dir


install_dir = config_dir('install_dir')
install_bin = join(install_dir, 'bin')

if not os.path.isdir(install_bin):
    raise ValueError(f"Invalid install_dir {install_dir}")

dst_dir = config_dir('dst_dir')

cluster_dir = join(dst_dir, server)


def check_cluster_file(relative: str):
    dir = join(cluster_dir, relative)
    if not os.path.isfile(dir):
        raise ValueError(
            f"Invalid cluster folder {cluster_dir} {dir}; please follow server setup (TODO link)")


check_cluster_file('cluster.ini')
check_cluster_file('cluster_token.txt')
check_cluster_file('Master/server.ini')
check_cluster_file('Caves/server.ini')

# Run script

if not args.no_update:
    header_print(f"Updating {dst_dir}")
    subprocess.run(['steamcmd', '+force_install_dir', install_dir, '+login',
                    'anonymous', '+app_update', '343050', 'validate', '+quit'])

header_print(f"Setting up {server}")


def copy_config_file(source_relative: str, dest_file: str):
    source_file = join(server_dir, source_relative)
    if os.path.isfile(source_file):
        print(f"{source_relative} -> {dest_file}")
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

header_print(f"Starting {server}")

async def start_shard(shard: str):
    run_commands = [join(BASE_DIR, 'scripts', 'start_shard.sh'), server, shard, str(os.getpid())]
    ps = subprocess.Popen(run_commands, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=install_bin)
    for line in ps.stdout:
        print(line.decode(), end='')
        await asyncio.sleep(1)
    ps.stdout.close()
    return_code = ps.wait()
    if return_code:
        raise subprocess.CalledProcessError(return_code, ps.args)

loop = asyncio.get_event_loop()
loop.create_task(start_shard('Caves'))
loop.create_task(start_shard('Master'))
loop.run_forever()