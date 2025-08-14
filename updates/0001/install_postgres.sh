#!/usr/bin/bash
set -e

sudo apt -y install postgresql
sudo -u postgres psql -c "\password"    