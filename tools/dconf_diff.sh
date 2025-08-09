#!/usr/bin/bash
set -e

echo -e "\ndconf_diff"

echo -e "\nIdentify updated dconf keys/values after making changes to Ubuntu settings."
echo -e "If differences are found, use dconf Editor's search function to find the key(s).\n"

dconf dump / > /tmp/dconf_before.ini

read -p "Make the required changes, then press a key to view the differences (if any)... "

echo ""

dconf dump / > /tmp/dconf_after.ini
diff --suppress-common-lines -y /tmp/dconf_before.ini /tmp/dconf_after.ini

