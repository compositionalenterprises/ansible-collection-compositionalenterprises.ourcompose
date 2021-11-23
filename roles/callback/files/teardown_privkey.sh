#!/bin/bash

# Let's just remove any files with the passed domain
# TODO: We should verify the source of the command before removing it from the server based on an
#       anonymous request.
find "${HOME}/instance_privkeys" -name "*${i}.privkey" -exec rm {} \;
