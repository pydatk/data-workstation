#!/usr/bin/bash
set -e

sudo -u postgres psql -c 'REVOKE connect ON DATABASE postgres FROM PUBLIC;'