#!/bin/bash

THIS_SCRIPT_PATH=${0}

md5sum ${THIS_SCRIPT_PATH} > ${THIS_SCRIPT_PATH}.md5
wget -O ${THIS_SCRIPT_PATH}.new https://raw.githubusercontent.com/dbrignoli/ubuntu-preseed-test/master/tcs-connect/start.sh && mv -f ${THIS_SCRIPT_PATH}.new ${THIS_SCRIPT_PATH}
# if the updated script does not match the running one, restart
md5sum -c ${THIS_SCRIPT_PATH}.md5 || exec ${THIS_SCRIPT_PATH}
chmod a+x ${THIS_SCRIPT_PATH}

echo "done."
