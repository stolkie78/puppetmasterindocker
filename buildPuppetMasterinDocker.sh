#!/bin/bash
set -e
####### Variables
EL=7
BASE_IMAGE=centos:${EL}
PUPPET_VERSION="2019.0.2"
INSTALL_FILE="puppet-enterprise-${PUPPET_VERSION}-el${EL}-x86_64.tar.gz"
IMAGE_NAME="puppet-enterprise:${PUPPET_VERSION}-${EL}"
PUPPET_MASTER_HOSTNAME="docpup.example.com"
PUPPET_MASTER_ALIASES="puppet, docpup.public.example.com"
ADMIN_PASSWORD="Welkom123#"
###### End Variables #######

echo "------------------"
echo "Ophalen base image"
echo "------------------"
docker pull ${BASE_IMAGE}

echo "-------------------------------"
echo "Ophalen Puppet server installer"
echo "-------------------------------"
if [ ! -f ${INSTALL_FILE} ]; then
  curl -L "https://pm.puppet.com/cgi-bin/download.cgi?dist=el&rel=${EL}&arch=x86_64&ver=${PUPPET_VERSION}" --output "${INSTALL_FILE}"
fi
tar xvf "${INSTALL_FILE}"

echo "----------------------"
echo "Prepare image starten"
echo "----------------------"
docker run -d -it --name create-puppet-image -h ${PUPPET_MASTER_HOSTNAME} -v ${PWD}:/root/puppet "${BASE_IMAGE}"

echo "----------------------"
echo "Installatie starten"
echo "----------------------"
docker exec -it create-puppet-image /root/puppet/installPuppet.sh "${PUPPET_VERSION}" "${INSTALL_FILE}" "${IMAGE_NAME}" "${PUPPET_MASTER_HOSTNAME}" "${ADMIN_PASSWORD}" "${PUPPET_MASTER_ALIASES}" "${EL}"

echo "--------------------------"
echo "Enterprise container maken"
echo "--------------------------"
docker stop create-puppet-image
docker commit \
-c 'EXPOSE 443' \
-c 'EXPOSE 8140' \
-c 'EXPOSE 8142' \
-c 'EXPOSE 61613' \
--change='CMD /usr/local/bin/start-puppet-enterprise && /usr/local/bin/start-puppet-enterprise && echo Started Puppet Enterprise && tail -f /var/log/puppetlabs/console-services/console-services*' \
create-puppet-image "${IMAGE_NAME}"

docker tag ${IMAGE_NAME} topaasbsbm.azurecr.io/tools/${IMAGE_NAME}
docker push topaasbsbm.azurecr.io/tools/${IMAGE_NAME}
docker rm create-puppet-image -f
