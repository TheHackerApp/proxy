#!/bin/sh

set -eu

FILE=/etc/nginx/snippets.d/cloudflare-ips.conf
mkdir -p "$(dirname $FILE)"

echo "# Cloudflare IP Ranges (last updated $(date))" > $FILE

echo "# IPv4" >> $FILE
for ip in $(wget -qO- https://www.cloudflare.com/ips-v4); do
  echo "set_real_ip_from $ip;" >> $FILE
done

echo "# IPv6" >> $FILE
for ip in $(wget -qO- https://www.cloudflare.com/ips-v6); do
  echo "set_real_ip_from $ip;" >> $FILE
done

nginx -t
if [ -z "${GENERATE_ONLY:-}" ]; then
  nginx -s reload
fi
