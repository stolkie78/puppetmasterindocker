#!/bin/bash

####### Variables
INSTALL_FILE="${2}"
PUPPET_VERSION="${1}"
IMAGE_NAME="${3}"
ADMIN_PASSWORD="${5}"
PUPPET_MASTER_HOSTNAME="${4}"
PUPPET_MASTER_ALIASES="${6}"
EL="${7}"
####### End Variables #######

# enable nexus repo
cp /root/puppet/NS_BSBM_INSTALL.repo /etc/yum.repos.d/NS_BSBM_INSTALL.repo
cp /root/puppet/systemctl.py /usr/bin/systemctl
chmod 755 /usr/bin/systemctl

yum -y update
yum -y install gettext crontabs glibc openssh-server openssh-clients sudo java-1.8.0-openjdk git-ns wget unzip python 
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

cd /root/puppet
cd puppet-enterprise-${PUPPET_VERSION}-el-${EL}-x86_64

# Create a pe.conf file
cat > pe.conf <<'PECONF'
{
  "console_admin_password": "ADMIN_PASSWORD",
  "puppet_enterprise::puppet_master_host": "PUPPET_MASTER_HOSTNAME",
  "pe_install::puppet_master_dnsaltnames": [
    "PUPPET_MASTER_ALIASES",
  ]
}
PECONF

# Configure pe.conf
sed -i "s/ADMIN_PASSWORD/${ADMIN_PASSWORD}/g" pe.conf && \
sed -i "s/PUPPET_MASTER_HOSTNAME/${PUPPET_MASTER_HOSTNAME}/g" pe.conf && \
sed -i "s/PUPPET_MASTER_ALIASES/${PUPPET_MASTER_ALIASES}/g" pe.conf

echo "Start puppet-enterprise-installer"
./puppet-enterprise-installer -c pe.conf

# To complete the setup of this system
echo "Run puppet agent -t twice"
puppet agent -t
puppet agent -t

# Add jenkins user
useradd jenkins
usermod -a -G pe-puppet jenkins
cp -r /root/puppet/.ssh /home/jenkins/
chown -R jenkins:jenkins /home/jenkins/.ssh
chmod -R 700 /home/jenkins/.ssh
chmod -R 600 /home/jenkins/.ssh/*
mkdir /jenkins
chown jenkins:jenkins /jenkins
mkdir /data
chown jenkins:jenkins /data
chown jenkins:jenkins /etc/puppetlabs/code/environments

cat > /etc/sudoers.d/jenkins <<'JENKINSSUDO'
jenkins          ALL=(ALL) NOPASSWD:   ALL
JENKINSSUDO

ln -s /usr/local/git/bin/git /usr/local/bin/git

# install jq for json parsing
curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 --output /usr/local/bin/jq
chmod +x /usr/local/bin/jq

# configure puppet for filesync
groupId=$(curl -s 'https://docpup.example.com:4433/classifier-api/v1/groups' \
        -H "Content-Type: application/json" \
        --cert $(puppet config print hostcert) \
        --key $(puppet config print hostprivkey) \
        --cacert $(puppet config print localcacert) \
        | jq --raw-output '.[] | select(.name=="All Environments") | .id')

curl -X POST -H 'Content-Type: application/json' \
        --cert $(puppet config print hostcert) \
        --key $(puppet config print hostprivkey) \
        --cacert $(puppet config print localcacert) \
        -d '{ "name": "badbam_o9_bam",
       "parent": "'"${groupId}"'",
       "environment": "badbam_o9_bam",
       "environment_trumps": true,
       "classes": {}
     }' https://docpup.example.com:4433/classifier-api/v1/groups

curl -X POST -H 'Content-Type: application/json' \
        --cert $(puppet config print hostcert) \
        --key $(puppet config print hostprivkey) \
        --cacert $(puppet config print localcacert) \
        -d '{ "name": "badbam_o9_bestdb",
       "parent": "'"${groupId}"'",
       "environment": "badbam_o9_bestdb",
       "environment_trumps": true,
       "classes": {}
     }' https://docpup.example.com:4433/classifier-api/v1/groups

groupId=$(curl -s 'https://docpup.example.com:4433/classifier-api/v1/groups' \
       -H "Content-Type: application/json" \
       --cert $(puppet config print hostcert) \
       --key $(puppet config print hostprivkey) \
       --cacert $(puppet config print localcacert) \
       | jq --raw-output '.[] | select(.name=="badbam_o9_bam") | .id')

curl -X POST -H 'Content-Type: application/json'   \
     --cert $(puppet config print hostcert)   \
     --key $(puppet config print hostprivkey)   \
     --cacert $(puppet config print localcacert) \
     -d '{"nodes": ["bam01.example.com", "bam02.example.com"]}'   \
     https://docpup.example.com:4433/classifier-api/v1/groups/$groupId/pin

groupId=$(curl -s 'https://docpup.example.com:4433/classifier-api/v1/groups' \
      -H "Content-Type: application/json" \
      --cert $(puppet config print hostcert) \
      --key $(puppet config print hostprivkey) \
      --cacert $(puppet config print localcacert) \
      | jq --raw-output '.[] | select(.name=="badbam_o9_bestdb") | .id')

curl -X POST -H 'Content-Type: application/json'   \
    --cert $(puppet config print hostcert)   \
    --key $(puppet config print hostprivkey)   \
    --cacert $(puppet config print localcacert) \
    -d '{"nodes": ["db05.example.com"]}'   \
    https://docpup.example.com:4433/classifier-api/v1/groups/$groupId/pin

groupId=$(curl -s 'https://docpup.example.com:4433/classifier-api/v1/groups' \
        -H "Content-Type: application/json" \
        --cert $(puppet config print hostcert) \
        --key $(puppet config print hostprivkey) \
        --cacert $(puppet config print localcacert) \
        | jq --raw-output '.[] | select(.name=="PE Master") | .id')

curl -X POST -H 'Content-Type: application/json'   \
    --cert $(puppet config print hostcert)   \
    --key $(puppet config print hostprivkey)   \
    --cacert $(puppet config print localcacert) \
    -d '{ "classes": {"puppet_enterprise::profile::master": {"file_sync_enabled": true} } }' \
    https://docpup.example.com:4433/classifier-api/v1/groups/$groupId

curl -X POST -H 'Content-Type: application/json'   \
    --cert $(puppet config print hostcert)   \
    --key $(puppet config print hostprivkey)   \
    --cacert $(puppet config print localcacert) \
    -d '{ "classes": {"puppet_enterprise::profile::master": {"environmentpath": "/etc/puppetlabs/code/environments"} } }' \
    https://docpup.example.com:4433/classifier-api/v1/groups/$groupId

curl -X POST -H 'Content-Type: application/json'   \
    --cert $(puppet config print hostcert)   \
    --key $(puppet config print hostprivkey)   \
    --cacert $(puppet config print localcacert) \
    -d '{ "classes": {"puppet_enterprise::profile::master": {"codedir": "/etc/puppetlabs/code/environments"} } }' \
    https://docpup.example.com:4433/classifier-api/v1/groups/$groupId

curl -X POST -H 'Content-Type: application/json'   \
    --cert $(puppet config print hostcert)   \
    --key $(puppet config print hostprivkey)   \
    --cacert $(puppet config print localcacert) \
    -d '{ "config_data": {"puppet_enterprise::master::file_sync": {"file_sync_staging_dir": "/etc/puppetlabs/code-staging/environments"} } }' \
    https://docpup.example.com:4433/classifier-api/v1/groups/$groupId

curl -X POST -H 'Content-Type: application/json'   \
    --cert $(puppet config print hostcert)   \
    --key $(puppet config print hostprivkey)   \
    --cacert $(puppet config print localcacert) \
    -d '{ "classes": {"pe_repo::platform::el_7_x86_64": {} } }' \
    https://docpup.example.com:4433/classifier-api/v1/groups/$groupId

mkdir /etc/puppetlabs/code-staging
chown pe-puppet:pe-puppet  /etc/puppetlabs/code-staging

# To complete the setup of this system
echo "Run puppet agent -t twice"
puppet agent -t
puppet agent -t

# install eyaml
/opt/puppetlabs/puppet/bin/gem install hiera-eyaml
/opt/puppetlabs/bin/puppetserver gem install hiera-eyaml

# Create an ENTRYPOINT file
cat > /usr/local/bin/start-puppet-enterprise <<'ENTRYPOINT'
#!/bin/bash
set -x

puppet resource pe_file_line ensure=present line='autosign = true' path=/etc/puppetlabs/puppet/puppet.conf
puppet config set autosign true --section master

#puppet cert clean db05.example.com bam01.example.com bam02.example.com bam03.example.com bam04.example.com
systemctl start pe-puppetdb.service
systemctl start pe-postgresql.service
systemctl start pe-puppetserver.service	
systemctl start pe-console-services.service
systemctl start pe-bolt-server.service
systemctl start pe-nginx.service
systemctl start pe-orchestration-services.service
#systemctl start pe-plan-executor.service

ENTRYPOINT

# Change permissions
chmod +x /usr/local/bin/start-puppet-enterprise
