#!/bin/bash
set -e
####### Variables
EL=7
BASE_IMAGE=centos:${EL}em
PUPPET_VERSION="2019.8.1"
INSTALL_FILE="puppet-enterprise-${PUPPET_VERSION}-el${EL}-x86_64.tar.gz"
DIR_NAME="puppet-enterprise-${PUPPET_VERSION}-el${EL}-x86_64"
IMAGE_NAME="puppet-enterprise:${PUPPET_VERSION}-${EL}"
PUPPET_MASTER_HOSTNAME="pe.example.com"
###### End Variables #######

echo "------------------------------------"
echo "Bouwen EM Centos Image met systemd"
echo "------------------------------------"
docker build . -t "${BASE_IMAGE}" --network host

echo "-------------------------------"
echo "Ophalen Puppet server installer"
echo "-------------------------------"
test -f ${INSTALL_FILE} || curl -L "https://pm.puppet.com/cgi-bin/download.cgi?dist=el&rel=${EL}&arch=x86_64&ver=${PUPPET_VERSION}" --output "${INSTALL_FILE}"

echo "-------------------------------"
echo "Uitpakken Puppet server installer"
echo "-------------------------------"
test -d "${DIR_NAME}" tar xf "${INSTALL_FILE}"

echo "--------------------------"
echo "Prepare image starten"
echo "--------------------------"
docker run -d --privileged --network host --name create-puppet-image -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v "${PWD}":/root/puppet -h "${PUPPET_MASTER_HOSTNAME}" -it "${BASE_IMAGE}"
    
echo "--------------------------"
echo "Installatie starten"
echo "--------------------------"
docker exec -it create-puppet-image  "/root/puppet/puppet-enterprise-${PUPPET_VERSION}-el-${EL}-x86_64/puppet-enterprise-installer" -c "/root/puppet/pe.conf"

echo "--------------------------"
echo "Create container"
echo "--------------------------"
docker stop create-puppet-image
docker commit \
-c 'EXPOSE 443' \
-c 'EXPOSE 8140' \
-c 'EXPOSE 8142' \
-c 'EXPOSE 61613' \
create-puppet-image "${IMAGE_NAME}"
docker rm create-puppet-image -f