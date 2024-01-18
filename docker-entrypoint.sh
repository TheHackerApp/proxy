#!/bin/sh

set -e

SELF=$(basename "$0")
entrypoint_log() {
  if [ -z "${ENTRYPOINT_QUIET:-}" ]; then
    echo "$SELF:" "$@"
  fi
}

if [ "$1" = "nginx" ] || [ "$1" = "openresty" ]; then
  config_files=$(find /docker-entrypoint.d/ -mindepth 1 -maxdepth 1 -type f -print -quit | wc -l)
  if [ "$config_files" != 0 ]; then
    entrypoint_log /docker-entrypoint.d/ is not empty, will attempt to perform configuration

    entrypoint_log Looking for shell scripts in /docker-entrypoint.d/
    find "/docker-entrypoint.d" -follow -type f -print | sort -V | while read -r f; do
      case "$f" in
        *.envsh)
          if [ -x "$f" ]; then
            entrypoint_log "Sourcing $f"
            # shellcheck source=/dev/null
            . "$f"
          else 
            entrypoint_log "Ignoring $f, not executable"
          fi
          ;;
        
        *.sh)
          if [ -x "$f" ]; then
            entrypoint_log "Launching $f";
            "$f"
          else 
            entrypoint_log "Ignoring $f, not executable"
          fi
          ;;
        
        *)
          entrypoint_log "Ignoring $f"
          ;;
      esac
    done

    entrypoint_log "Configuration complete; ready for start up"
  else
    entrypoint_log No files found in /docker-entrypoint.d/, skipping configuration
  fi
fi

crond -L /var/log/crond

exec "$@"
