#!/bin/sh

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl --silent --max-time 2 --insecure https://localhost:8888/ -o /dev/null || errorExit "Error GET https://localhost:8888/"
if ip addr | grep -q 10.0.75.80; then
    curl --silent --max-time 2 --insecure https://10.0.75.80:8888/ -o /dev/null || errorExit "Error GET https://10.0.75.80:8888/"
fi
