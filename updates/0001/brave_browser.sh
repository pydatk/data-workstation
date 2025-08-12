#!/usr/bin/bash
set -e

sudo apt -y install curl
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
sudo apt -y update
sudo apt -y install brave-browser