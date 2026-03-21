#!/bin/bash
set -euo pipefail

for attempt in 1 2 3 4 5; do
  if mongosh --host mongo:27017 --eval "
    try { rs.status() }
    catch(e) { rs.initiate({ _id: 'overleaf', members: [{ _id: 0, host: 'mongo:27017' }] }) }
  "; then
    echo "[mongo-init] Replica set ready."
    exit 0
  fi
  echo "[mongo-init] Attempt $attempt failed, retrying in 3s..."
  sleep 3
done

echo "[mongo-init] Failed after 5 attempts"
exit 1
