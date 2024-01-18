#!/bin/sh

set -e

SELF=$(basename "$0")
entrypoint_log() {
  if [ -z "${ENTRYPOINT_QUIET:-}" ]; then
    echo "$SELF:" "$@"
  fi
}

static_dir="${NGINX_STATIC_DIR:-/usr/local/openresty/nginx/conf/conf.d}"
output_dir="${NGINX_STATIC_OUTPUT_DIR:-/etc/nginx/conf.d}"

[ -d "$static_dir" ] || return 0
if [ ! -w "$output_dir" ]; then
  entrypoint_log "ERROR: $static_dir exists, but $output_dir is not writable"
  return 0
fi

relocatable=$( { cd "$static_dir" && find . -type f -print; } | cut -c 3-)
for f in $relocatable; do
  ln -sf "$static_dir/$f" "$output_dir/$f"
done
