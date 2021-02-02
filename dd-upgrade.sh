#/bin/bash
cd /tmp
apikey=$(aws ssm get-parameter --name daik-nonprod-datadog-apikey --with-decryption --region ap-southeast-2 --query \"Parameter.Value\")
if [ $? -ne 0 ]; then
echo 'ERROR! Unable to retrieve the API Key from the Parameter Store, exiting.'
exit 8
fi
if [ -f /tmp/ddagent-install.log ]; then
mv /tmp/ddagent-install.log /tmp/ddagent-install-log.old
fi
if [ -f /etc/datadog-agent/datadog.yaml ]; then
dd_host=$(/usr/bin/datadog-agent -n hostname)
echo 'Host:' $dd_host
dd_ver_current=$(/usr/bin/datadog-agent -n version)
echo 'Version:' $dd_ver_current
dd_platform=$(/usr/bin/datadog-agent status | grep 'platform:' | sed -e 's/.*://' | awk '{$1=$1};1')
echo 'Platform:' $dd_platform
if [ \"$dd_platform\" == \"suse\" ]; then
echo 'Running upgrade script for:' $dd_platform
DD_AGENT_MAJOR_VERSION={{ version }} DD_API_KEY=$apikey bash -c \"$(curl -L -s https://raw.githubusercontent.com/DataDog/datadog-agent/master/md/agent/install_script.sh)\" > /dev/null 2>&1
elif [ $dd_platform == 'amazon' ]; then
echo 'Running upgrade script for:' $dd_platform
DD_AGENT_MAJOR_VERSION={{ version }} DD_API_KEY=$apikey bash -c \"$(curl -L -s https://raw.githubusercontent.com/DataDog/datadog-agent/master/md/agent/install_script.sh)\" > /dev/null 2>&1
else
echo 'ERROR! Upgrade script for the platform was not found, exiting.'
exit 8
fi
if [ $? -ne 0 ]; then
echo 'ERROR! Unable to upgrade, install_script.sh error, exiting.'
exit 8
fi
dd_ver_post=$(/usr/bin/datadog-agent -n version)
systemd_status=$(systemctl is-active datadog-agent.service)
echo 'Service Status:' $systemd_status
if [ \"$dd_ver_current\" == \"$dd_ver_post\" ]; then
echo 'Upgrade not required, skipping.'
else
echo 'Upgraded to:' $dd_ver_post
echo 'Upgrade completed.'
fi
if [ -f /tmp/ddagent-install.log ]; then
mv /tmp/ddagent-install.log /tmp/ddagent-install-log.$(date +%s)
rm -f  $(ls -1t /tmp/ddagent-install-log.* | tail -n +11)
fi
else
echo 'WARNING! Datadog agent not installed.'
fi"
exit
