#!/bin/sh

set -e

SELF=$(basename "$0")
entrypoint_log() {
  if [ -z "${ENTRYPOINT_QUIET:-}" ]; then
    echo "$SELF:" "$@"
  fi
}

template_dir="${NGINX_ENVSUBST_TEMPLATE_DIR:-/usr/local/openresty/nginx/templates}"
suffix="${NGINX_ENVSUBST_TEMPLATE_SUFFIX:-.template}"
output_dir="${NGINX_ENVSUBST_OUTPUT_DIR:-/etc/nginx/conf.d}"
filter="${NGINX_ENVSUBST_FILTER:-}"

[ -d "$template_dir" ] || return 0
if [ ! -w "$output_dir" ]; then
  entrypoint_log "ERROR: $template_dir exists, but $output_dir is not writable"
  return 0
fi

# shellcheck disable=SC2016,SC2046
defined_envs=$(printf '${%s} ' $(awk "END { for (name in ENVIRON) { print ( name ~ /${filter}/ ) ? name : \"\" } }" < /dev/null ))

find "$template_dir" -follow -type f -name "*$suffix" -print | while read -r template; do
  relative_path="${template#"$template_dir/"}"
  output_path="$output_dir/${relative_path%"$suffix"}"
  subdir=$(dirname "$relative_path")
  # create a subdirectory where the template file exists
  mkdir -p "$output_dir/$subdir"
  entrypoint_log "Running envsubst on $template to $output_path"
  envsubst "$defined_envs" < "$template" > "$output_path"
done

