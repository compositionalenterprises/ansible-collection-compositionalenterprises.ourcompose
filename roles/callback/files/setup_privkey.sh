#!/bin/bash

CURR=10000

# We're just going until we see an unused number > 10000
while true; do
  # This is testing if any file starts with that number in the dir
  if /bin/ls $HOME/instance_privkeys/${CURR}* > /dev/null 2>&1; then
    CURR=$(( CURR + 1 ));
  else
    # Here we setup the privkey inside of that dir
    echo -e "${1}" > "$HOME/instance_privkeys/${CURR}.${2}.privkey"
    /bin/chmod 0600 "$HOME/instance_privkeys/${CURR}.${2}.privkey"
    echo ${CURR}
    break;
  fi;
done
