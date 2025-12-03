#!/bin/sh

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl --silent --max-time 2 --insecure https://localhost:8888/ -o /dev/null || errorExit "Error GET https://localhost:8888/"
if ip addr | grep -q  192.168.0.50; then
    curl --silent --max-time 2 --insecure https:// 192.168.0.50:8888/ -o /dev/null || errorExit "Error GET https:// 192.168.0.50:8888/"
fi
