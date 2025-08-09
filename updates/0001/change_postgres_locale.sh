#!/usr/bin/bash
set -e

read -p "enter new locale (e.g. en_NZ.utf8 for New Zealand UTF8): " input
sudo locale-gen $input
sudo update-locale
locale -a
sudo service postgresql restart