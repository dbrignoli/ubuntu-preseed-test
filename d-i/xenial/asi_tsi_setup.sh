#!/bin/sh

# Disable SSH password authentication
echo "\nPasswordAuthentication no\n" >> /etc/ssh/sshd_config
# Download and setup latest version of tcs-connect bootstrap script
mkdir -p /home/tsm/tcs-connect/start.sh
wget -O /home/tsm/tcs-connect/start.sh https://raw.githubusercontent.com/dbrignoli/ubuntu-preseed-test/master/tcs-connect/start.sh
chown tsm.tsm /home/tsm/tcs-connect/start.sh
chmod a+x /home/tsm/tcs-connect/start.sh
# Setup tcs-connect system-wide service
wget -O /etc/systemd/system/tcs-connect.service https://raw.githubusercontent.com/dbrignoli/ubuntu-preseed-test/master/tcs-connect/tcs-connect.service
systemctl enable tcs-connect
# Leave something to prove we were here ;)
touch /asi_tsi_setup_done
