#!/bin/sh

set -e

find /usr/local/openresty/nginx -type f -name '*.default' -exec rm -f {} \;
