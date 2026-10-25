#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$ROOT_DIR/server"
RUNTIME_DIR="$SERVER_DIR/runtime"
USER_AGENT='minecraft-xray-server-setup/1.0 (https://github.com/bliotti)'

mkdir -p "$SERVER_DIR" "$RUNTIME_DIR" "$SERVER_DIR/plugins"

if [[ ! -f "$SERVER_DIR/eula.txt" ]]; then
  cat <<'PROMPT'
Minecraft Java server EULA: https://www.minecraft.net/eula
Read the EULA before continuing. Do you agree to it? Type yes to continue:
PROMPT
  read -r answer
  if [[ "$answer" != "yes" ]]; then
    echo 'Setup stopped. No EULA acceptance was recorded.' >&2
    exit 1
  fi
  printf 'eula=true\n' > "$SERVER_DIR/eula.txt"
fi

PAPER_META="$(curl -fsSL -H "User-Agent: $USER_AGENT" \
  https://fill.papermc.io/v3/projects/paper/versions/26.3/builds)"
PAPER_URL="$(jq -r 'first(.[] | select(.channel == "STABLE") | .downloads."server:default".url)' <<<"$PAPER_META")"
PAPER_SHA="$(jq -r 'first(.[] | select(.channel == "STABLE") | .downloads."server:default".checksums.sha256)' <<<"$PAPER_META")"
if [[ -z "$PAPER_URL" || "$PAPER_URL" == null || -z "$PAPER_SHA" || "$PAPER_SHA" == null ]]; then
  echo 'Could not find a stable Paper 26.3 download.' >&2
  exit 1
fi
curl -fL "$PAPER_URL" -o "$SERVER_DIR/paper.jar"
printf '%s  %s\n' "$PAPER_SHA" "$SERVER_DIR/paper.jar" | sha256sum -c -

JAVA_META="$(curl -fsSL \
  'https://api.adoptium.net/v3/assets/latest/25/hotspot?architecture=x64&image_type=jre&os=linux')"
JAVA_URL="$(jq -r '.[0].binary.package.link' <<<"$JAVA_META")"
JAVA_SHA="$(jq -r '.[0].binary.package.checksum' <<<"$JAVA_META")"
if [[ -z "$JAVA_URL" || "$JAVA_URL" == null || -z "$JAVA_SHA" || "$JAVA_SHA" == null ]]; then
  echo 'Could not find a Temurin Java 25 JRE download.' >&2
  exit 1
fi
JAVA_ARCHIVE="$SERVER_DIR/temurin-jre25.tar.gz"
curl -fL "$JAVA_URL" -o "$JAVA_ARCHIVE"
printf '%s  %s\n' "$JAVA_SHA" "$JAVA_ARCHIVE" | sha256sum -c -
tar -xzf "$JAVA_ARCHIVE" -C "$RUNTIME_DIR"
rm "$JAVA_ARCHIVE"

OREWATCH_URL='https://cdn.modrinth.com/data/Yn567I4t/versions/9E4d8AvQ/OreWatch-2.0.jar'
OREWATCH_SHA512='0cda48ba24c3b2f1487e6f3fa3f8ddef877941d64195f5afd267ba2201b37a3094af2bb04cd9c884003f61d8a88b777d8d07d974a6527f5a099d92f5b6dcd5c1'
curl -fL "$OREWATCH_URL" -o "$SERVER_DIR/plugins/OreWatch.jar"
printf '%s  %s\n' "$OREWATCH_SHA512" "$SERVER_DIR/plugins/OreWatch.jar" | sha512sum -c -

if [[ ! -f "$SERVER_DIR/server.properties" ]]; then
  cp "$ROOT_DIR/server.properties.example" "$SERVER_DIR/server.properties"
fi

cat > "$SERVER_DIR/start.sh" <<'START'
#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
JAVA_BIN="$(find runtime -path '*/jdk-25*/bin/java' -print -quit)"
if [[ -z "$JAVA_BIN" ]]; then
  echo 'Java 25 runtime not found. Run ../setup.sh first.' >&2
  exit 1
fi
exec "$JAVA_BIN" -Xms1G -Xmx2G -jar paper.jar --nogui
START
chmod +x "$SERVER_DIR/start.sh"
printf '\nSetup complete. Start the server with: %s/server/start.sh\n' "$ROOT_DIR"
