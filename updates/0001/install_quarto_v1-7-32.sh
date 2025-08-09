#!/usr/bin/bash
set -e

wget -P /tmp/ https://github.com/quarto-dev/quarto-cli/releases/download/v1.7.32/quarto-1.7.32-linux-amd64.deb
sudo dpkg -i /tmp/quarto-1.7.32-linux-amd64.deb
rm /tmp/quarto-1.7.32-linux-amd64.deb