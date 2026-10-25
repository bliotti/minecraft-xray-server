# Temporary Minecraft X-ray server

A reproducible setup for a Minecraft Java 26.3 LAN server using Paper and the OreWatch plugin. The repository contains setup instructions and scripts; it does not contain the Minecraft server jar, Java runtime, plugin jar, generated worlds, or player data.

## Requirements

- Linux x86_64
- `curl`, `jq`, `sha256sum`, and `sha512sum`
- Java 25 is downloaded by the setup script

## Setup

```bash
./setup.sh
```

The script asks you to read and accept the [Minecraft EULA](https://www.minecraft.net/eula) before recording that acceptance locally. It downloads Paper 26.3, Temurin Java 25, and OreWatch 2.0, then verifies their published checksums where available.

Start the server in a terminal:

```bash
./server/start.sh
```

The server binds to available interfaces on TCP port `25565`. On the host, get its current LAN IPv4 address with `ip -4 -o addr show scope global`; connect from another computer on the same LAN using `<LAN-IP>:25565`. Do not configure router port forwarding for a LAN-only server. If the host firewall blocks connections, allow TCP port 25565 from the local subnet.

## OreWatch

OreWatch is an admin ore-vision tool. Operators can run `/xray` for its menu, `/xray all` to show all supported ores, or `/xray off` to turn highlighting off. To grant access to a player, run `op <playername>` in the server console. The plugin's X-ray shows glowing ore outlines through walls; it does not make terrain transparent.

## Stop and data

Enter `stop` in the server console to save and shut down cleanly. World data, logs, configuration, and the accepted EULA stay under the ignored `server/` directory and are not committed.
