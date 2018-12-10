#!/bin/bash
curl https://rclone.org/install.sh | sudo bash
wget -O - https://backup.vnclouds.co/install.sh > /root/.config/backup_vnc.sh --no-check-certificate
touch /etc/cron.d/backup
cat <<EOT >> /etc/cron.d/backup
echo "0 1 * * * root /root/.config/backup_vnc.sh > /dev/null 2>&1 /etc/cron.d" >> /etc/cron.d/backup
EOT