#!/bin/bash

THIS_SCRIPT_PATH=${0}
TCS_CONNECT_URL_PREFIX='https://raw.githubusercontent.com/dbrignoli/ubuntu-preseed-test/master/tcs-connect'
TCS_USERNAME=tcs
TCS_HOSTNAME=asi-tcs.ddns.net

download-update() {
	url=${TCS_CONNECT_URL_PREFIX}/$(basename $1)
	dest=$1
	wget -N -O ${dest}.new ${url} && mv -f ${dest}.new ${dest}
}

check-update-and-restart() {
	script=$1
	# check for updates to this script
	rm -f ${script}.md5
	md5sum ${script} > ${script}.md5
	download-update ${script}
	chmod a+x ${script}
	# if the updated script does not match the running one, restart
	md5sum -c ${script}.md5 || exec ${script}
}

tcs-reverse-tunnel() {
	user=$1
	host=$2
	keyfile_path=$3
	key_fingerprint=$(ssh-keygen -l -f ${keyfile_path})
	# 1. connect, get dynamic port, disconnect
	port=$(echo "exit" | ssh -F ssh_config -i ${keyfile_path} -R 0:127.0.0.1:22 ${user}@${host} 2>&1 | grep 'Allocated port' | awk '/port/ {print $3;}')
	# 2. reconnect with this port and set remote variable
	ssh -F ssh_config -i ${keyfile_path} -R ${port}:127.0.0.1:22 ${user}@${host} "echo \"${key_fingerprint}\" > rtunnel:$port; sleep 60"
}

cd $(dirname ${THIS_SCRIPT_PATH})

# Generate user key if it doesn't exist
rsa_key_path=${HOME}/.ssh/id_rsa
[ -e ${rsa_key_path} ] || ssh-keygen -N '' -f ${rsa_key_path}

check-update-and-restart ${THIS_SCRIPT_PATH}

# download other required files
download-update tcs_restricted_rsa
download-update tcs_host_rsa.pub
# set restricted private key permission
chmod 600 tcs_restricted_rsa

# build known_hosts file
echo -n "${TCS_HOSTNAME} " > tcs_host_key
cat tcs_host_rsa.pub | cut -d' ' -s -f1,2 >> tcs_host_key

# build local ssh config file
echo "PasswordAuthentication no" > ssh_config
echo "UserKnownHostsFile tcs_host_key" >> ssh_config

# Connect to TCS to deposit our public key
# TCS restricts access to receiveing SSH public keys
cat ${rsa_key_path}.pub | ssh -F ssh_config -i tcs_restricted_rsa ${TCS_USERNAME}@${TCS_HOSTNAME}
# This will suceed only if we were previously authorised
tcs-reverse-tunnel ${TCS_USERNAME} ${TCS_HOSTNAME} ${rsa_key_path}
