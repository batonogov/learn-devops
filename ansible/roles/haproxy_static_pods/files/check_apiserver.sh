#!/bin/sh

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl --silent --max-time 2 --insecure https://localhost:7443/ -o /dev/null || errorExit "Error GET https://localhost:7443/"
if ip addr | grep -q 10.0.70.85; then
    curl --silent --max-time 2 --insecure https://10.0.70.85:7443/ -o /dev/null || errorExit "Error GET https://10.0.70.85:7443/"
fi
