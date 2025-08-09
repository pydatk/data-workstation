#!/usr/bin/bash
set -e

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
status=$(sudo ufw status)
if [ "$status" != "Status: active" ]; then
    echo "ufw is not active"
    exit 1
fi