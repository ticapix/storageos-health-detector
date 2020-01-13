#!/bin/bash

readonly OK=0
readonly NONOK=1
readonly UNKNOWN=2

echo NODE: $NODE_NAME
echo Connection to $STORAGEOS_HOST using user $STORAGEOS_USERNAME

/storageos node ls || exit $UNKNOWN
/storageos volume ls || exit $UNKNOWN
count=`/storageos volume ls --format '{{ json .Health }}' | uniq | grep -v '^"healthy"$\|^[[:space:]]*$' | wc -l`

if [ "$count" -eq "0" ]; then
    exit $OK
else
    exit $NONOK
fi
