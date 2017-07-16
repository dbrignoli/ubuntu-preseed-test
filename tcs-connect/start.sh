#!/bin/bash

THIS_SCRIPT_PATH=${0}
TCS_CONNECT_URL_PREFIX='https://raw.githubusercontent.com/dbrignoli/ubuntu-preseed-test/master'

update() {
	url=$1
	dest=$2
	wget -O ${dest}.new ${url} && mv -f ${dest}.new ${dest}
}

# Generate user key if it doesn't exist
local_user=tsm
rsa_key_path=/home/${local_user}/.ssh/id_rsa
[ -e ${rsa_key_path} ] || ssh-keygen -N '' -f ${rsa_key_path}

# download other required files
update ${TCS_CONNECT_URL_PREFIX}/tcs-connect/tcs_restricted_rsa tcs_restricted_rsa
update ${TCS_CONNECT_URL_PREFIX}/tcs-connect/tcs_host_rsa.pub tcs_host_rsa.pub

# check for updates to this script
rm -f ${THIS_SCRIPT_PATH}.md5
md5sum ${THIS_SCRIPT_PATH} > ${THIS_SCRIPT_PATH}.md5
update ${TCS_CONNECT_URL_PREFIX}/tcs-connect/start.sh ${THIS_SCRIPT_PATH}
chmod a+x ${THIS_SCRIPT_PATH}
# if the updated script does not match the running one, restart
md5sum -c ${THIS_SCRIPT_PATH}.md5 || exec ${THIS_SCRIPT_PATH}

user=tcs
host=tcs.local

# build known_hosts file
echo "${host} " > tcs_host_key
cat tcs_host_rsa.pub | cut -d' ' -s -f1,2 >> tcs_host_key

# Connect to TCS to deposit our public key
# TCS restricts access to receiveing SSH public keys
cat ${rsa_key_path}.pub | ssh -o "UserKnownHostsFile tcs_host_key" -i tcs_restricted_rsa $user@$host

sshr() {
# 1. connect, get dynamic port, disconnect
port=`echo "exit" | ssh -o "UserKnownHostsFile tcs_host_key" -i ${rsa_key_path} -R 0:127.0.0.1:22 $1 2>&1 | grep 'Allocated port' | awk '/port/ {print $3;}'`
# 2. reconnect with this port and set remote variable
cmds="ssh -o \"UserKnownHostsFile tcs_host_key\" -i ${rsa_key_path} -R $port:127.0.0.1:22 -t $1 bash -c \"export RFWD_PORT=$port; exec bash\""
($cmds)
}

sshr $user@$host

echo "done."
