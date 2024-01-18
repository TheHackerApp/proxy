#!/bin/sh

set -e

exec gunicorn \
  --access-logfile - \
  --bind "0.0.0.0:8000" \
  --worker-tmp-dir /dev/shm \
  --workers "${GUNICORN_WORKERS:-1}" \
  echo:app
