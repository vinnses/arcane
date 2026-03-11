#!/bin/sh

TARGET_DIR="/var/lib/dav/data"

if [ -d "$TARGET_DIR" ]; then
    chown -R www-data:www-data "$TARGET_DIR"
    chmod -R 755 "$TARGET_DIR"
fi

if command -v docker-entrypoint.sh >/dev/null 2>&1; then
    exec docker-entrypoint.sh "$@"
elif [ -x "/usr/local/bin/docker-entrypoint.sh" ]; then
    exec /usr/local/bin/docker-entrypoint.sh "$@"
else
    exec "$@"
fi