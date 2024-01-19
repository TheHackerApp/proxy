#!/bin/sh

set -eu

# For whatever reason, there are OpenTelemetry environment variables injected into the build
# process by the docker/build-push-action. This was causing problems testing the OpenTelemetry C++
# SDK. To fix it, this script finds all environment variables starting with OTEL_ and unsets them.

for var in $(env | grep OTEL_ | cut -d= -f1); do
  unset $var
done

unset TRACEPARENT
