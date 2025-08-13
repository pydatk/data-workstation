#!/usr/bin/bash
set -e

if [ -f "$HOME/.data-workstation/.updates/.0001/.install_python_venv" ]; then
    # Fixes: https://github.com/pydatk/data-workstation/issues/31
    sudo apt -y remove python3.12-venv
fi

sudo apt -y install python3-venv