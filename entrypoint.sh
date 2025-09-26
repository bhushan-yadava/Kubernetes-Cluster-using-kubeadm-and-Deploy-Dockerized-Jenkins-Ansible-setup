#!/bin/bash
# simple entrypoint: run ansible playbook passed as arg, otherwise open shell
if [ -n "$1" ]; then
  exec ansible-playbook "$@"
else
  exec /bin/bash
fi
