#!/bin/bash
set -x
####### Variables
PUPPET_VERSION="${1}"
INSTALL_FILE="${2}"
IMAGE_NAME="${3}"
EL="${4}"
####### End Variables #######

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

cd /root/puppet
cd puppet-enterprise-${PUPPET_VERSION}-el-${EL}-x86_64

echo "Start puppet-enterprise-installer"
./puppet-enterprise-installer -c /root/puppet/pe.conf

# To complete the setup of this system
#echo "Run puppet agent -t twice"
#puppet agent -t
#puppet agent -t

# install eyaml
#/opt/puppetlabs/puppet/bin/gem install hiera-eyaml
#/opt/puppetlabs/bin/puppetserver gem install hiera-eyaml

#puppet config set autosign true --section master
#
#systemctl start pe-puppetdb.service
#systemctl start pe-postgresql.service
#systemctl start pe-puppetserver.service	
#systemctl start pe-console-services.service
#systemctl start pe-bolt-server.service
#systemctl start pe-nginx.service
#systemctl start pe-orchestration-services.service
##systemctl start pe-plan-executor.service
#
#ENTRYPOINT

# Change permissions
#chmod +x /usr/local/bin/start-puppet-enterprise
