#!/bin/sh

# Disable SSH password authentication
echo "\nPasswordAuthentication no\n" >> /etc/ssh/sshd_config

echo "Do stuff here"
# Leave something to prove we were here ;)
touch /asi_tsi_setup_done
