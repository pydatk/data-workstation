#!/usr/bin/bash
set -e

sudo apt install postgresql
sudo -u postgres psql -c "\password"    