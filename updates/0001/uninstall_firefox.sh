#!/usr/bin/bash
set -e

# solution from: https://askubuntu.com/a/16763

echo -e "\nPlease check that Firefox is closed.\n"

read -p "Press enter to continue... "

typeffx=$(type -p firefox)

if [ $typeffx == "/usr/bin/firefox" ]; then
    echo "Removing Firefox with apt"
    sudo apt remove firefox
fi

typeffx=$(type -p firefox)

if [ $typeffx == "/snap/bin/firefox" ]; then
    echo "Removing Firefox with snap"
    sudo snap remove firefox
fi