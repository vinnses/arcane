#!/bin/bash
# dump.sh — Atomic snapshot of Immich state for portable backup/restore
# Usage: ./dump.sh
#
# Creates a timestamped backup in <project>/.backup/<timestamp>/ containing:
#   - pg_dumpall.sql        (full postgres dump)
#   - .env.restore          (copy of current .env)
#   - manifest.json         (container digests, versions, metadata)
#
# No hardcoded paths — derives everything from its own location.

set -euo pipefail

# --- Context resolution ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$PROJECT_DIR/compose.yaml"
ENV_FILE="$PROJECT_DIR/.env"

if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo "[error] compose.yaml not found at $PROJECT_DIR" >&2
    exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
    echo "[error] .env not found at $PROJECT_DIR" >&2
    exit 1
fi

# --- Load env for DB credentials ---
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

DB_USER="${DB_USERNAME:-postgres}"

# --- Detect running containers ---
echo "[dump] Detecting running containers..."

# Get the compose project name from running containers
COMPOSE_PROJECT=$(docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps --format json 2>/dev/null \
    | head -1 | python3 -c "import sys,json; print(json.load(sys.stdin).get('Project',''))" 2>/dev/null || true)

if [[ -z "$COMPOSE_PROJECT" ]]; then
    # Fallback: detect from any immich container
    COMPOSE_PROJECT=$(docker inspect --format '{{index .Config.Labels "com.docker.compose.project"}}' \
        "$(docker ps --filter 'label=com.docker.compose.service=database' --format '{{.Names}}' | head -1)" 2>/dev/null || true)
fi

if [[ -z "$COMPOSE_PROJECT" ]]; then
    echo "[error] Cannot detect compose project. Are the containers running?" >&2
    exit 1
fi

echo "[dump] Compose project: $COMPOSE_PROJECT"

# Map service names to running container names
declare -A CONTAINERS
for service in immich-server immich-machine-learning redis database; do
    container=$(docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps --format '{{.Name}}' "$service" 2>/dev/null || true)

    # Fallback: search by compose labels
    if [[ -z "$container" ]] || ! docker inspect "$container" &>/dev/null; then
        container=$(docker ps \
            --filter "label=com.docker.compose.project=$COMPOSE_PROJECT" \
            --filter "label=com.docker.compose.service=$service" \
            --format '{{.Names}}' | head -1)
    fi

    if [[ -z "$container" ]]; then
        echo "[warn] Container for service '$service' not found (may be expected for optional services)" >&2
    else
        CONTAINERS[$service]="$container"
        echo "[dump] Service '$service' → container '$container'"
    fi
done

# --- Validate postgres is running ---
DB_CONTAINER="${CONTAINERS[database]:-}"
if [[ -z "$DB_CONTAINER" ]]; then
    echo "[error] Database container not found. Cannot dump." >&2
    exit 1
fi

if ! docker exec "$DB_CONTAINER" pg_isready -U "$DB_USER" &>/dev/null; then
    echo "[error] PostgreSQL is not ready in $DB_CONTAINER" >&2
    exit 1
fi

# --- Create backup directory ---
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
BACKUP_DIR="$PROJECT_DIR/.backup/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

echo "[dump] Backup directory: $BACKUP_DIR"

# --- 1. Postgres dump ---
echo "[dump] Dumping PostgreSQL..."
docker exec "$DB_CONTAINER" pg_dumpall -U "$DB_USER" > "$BACKUP_DIR/pg_dumpall.sql"
DUMP_SIZE=$(du -h "$BACKUP_DIR/pg_dumpall.sql" | cut -f1)
echo "[dump] PostgreSQL dump complete ($DUMP_SIZE)"

# --- 2. Copy .env ---
cp "$ENV_FILE" "$BACKUP_DIR/.env.restore"
echo "[dump] .env copied"

# --- 3. Collect container metadata ---
echo "[dump] Collecting container digests and versions..."

PG_VERSION=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -t -c "SELECT version();" 2>/dev/null | xargs)

# Build JSON manifest
MANIFEST="$BACKUP_DIR/manifest.json"
{
    echo "{"
    echo "  \"timestamp\": \"$TIMESTAMP\","
    echo "  \"compose_project\": \"$COMPOSE_PROJECT\","
    echo "  \"compose_file\": \"compose.yaml\","
    echo "  \"postgres_version\": \"$(echo "$PG_VERSION" | sed 's/"/\\"/g')\","
    echo "  \"services\": {"

    first=true
    for service in "${!CONTAINERS[@]}"; do
        container="${CONTAINERS[$service]}"
        # Config.Image = the tag used to create the container (e.g. :release)
        config_image=$(docker inspect "$container" --format '{{.Config.Image}}' 2>/dev/null || echo "unknown")
        # .Image = local image ID (not pullable)
        local_id=$(docker inspect "$container" --format '{{.Image}}' 2>/dev/null || echo "unknown")

        # RepoDigests = registry-pullable immutable reference (what we actually need)
        # If the image was pulled with a digest already (e.g. postgres@sha256:...),
        # Config.Image already contains it. Otherwise, resolve via RepoDigests.
        if [[ "$config_image" == *"@sha256:"* ]]; then
            pullable_image="$config_image"
        else
            pullable_image=$(docker image inspect "$config_image" --format '{{index .RepoDigests 0}}' 2>/dev/null || echo "$config_image")
        fi

        $first || echo ","
        first=false

        printf '    "%s": {\n' "$service"
        printf '      "container": "%s",\n' "$container"
        printf '      "image": "%s",\n' "$pullable_image"
        printf '      "local_id": "%s"\n' "$local_id"
        printf '    }'
    done

    echo ""
    echo "  }"
    echo "}"
} > "$MANIFEST"

echo "[dump] Manifest written"

# --- Summary ---
echo ""
echo "=== Dump complete ==="
echo "  Directory:  $BACKUP_DIR"
echo "  SQL dump:   $DUMP_SIZE"
echo "  Services:   ${#CONTAINERS[@]} captured"
echo "  Manifest:   $MANIFEST"
echo ""
echo "Contents:"
ls -lh "$BACKUP_DIR/"
echo ""
echo "To restore on this or another device:"
echo "  ./scripts/restore.sh $BACKUP_DIR"
