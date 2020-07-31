# DST Dedicated Server

Helper scripts for setting up and managing a DST server

## Setup

Follow the first two steps at
https://forums.kleientertainment.com/forums/topic/64441-dedicated-server-quick-setup-guide-linux/

For Debian, see https://unix.stackexchange.com/a/390076 for `steamcmd` installation

---

Update config files by creating `config.cfg`. 
You can use `config.cfg.defaults` for reference, or skip this step if defaults are fine.

---

All commands are called from `dst.sh`. You may optionally add an alias so you can call this from any location.
For the rest the doc, I will refer to this script as `dst`.

All steps of the script are documented via `-h|--help|help`

## Create Server

Create server via https://accounts.klei.com/account/game/servers?game=DontStarveTogether

Call `dst setup [server_zip]`, where `server_zip` is the path to the zip file.
This will move the zip to the appropriate folder (named after the configuration, not the zip name), along with a template for server overrides.
By default, the server will be vanilla DST. To add mods or change world generation, look at the newly created folder under `servers`

## Server Start

Call `dst start [server_name]`

## Misc Info

* [Server Requirements](https://support.klei.com/hc/en-us/articles/360029556072-Don-t-Starve-Together-System-Requirements)
* [Staff Guide](https://forums.kleientertainment.com/forums/topic/64441-dedicated-server-quick-setup-guide-linux/)
* This guide is based around Google Cloud, where I'm using a compute engine + Debian
* If you wish to run a server 24/7 and don't require full access to your server, you can consider a gaming server. Some servers will have DST pre configured, but note that you may require two instances to support both the main world + caves
