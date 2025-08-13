#!/usr/bin/bash
set -e

sudo apt -y update
sudo apt -y install nginx

sudo adduser $USER www-data
sudo chown $USER:www-data -R /var/www/html

sudo chown $USER:www-data -R /var/www/html
sudo chmod u=rwX,g=srX,o=rX -R /var/www/html
sudo find /var/www/html -type d -exec chmod g=rwxs "{}" \;
sudo find /var/www/html -type f -exec chmod g=rws "{}" \;

sudo systemctl reload nginx