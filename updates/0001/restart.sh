 #!/usr/bin/bash
set -e

echo -e "\nMachine will restart. Re-run setup after system reboot to complete final steps.\n"

read -p "Press any key to restart machine... " 

sudo reboot