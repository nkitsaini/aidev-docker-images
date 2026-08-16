#!/bin/bash

# Delegate to Vast's boot dispatcher. The image entrypoint invokes this in args
# mode; /etc/rc.local invokes it when Vast replaces the entrypoint with /.launch.
exec /opt/instance-tools/bin/entrypoint.sh "$@"
