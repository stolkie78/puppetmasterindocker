#!/bin/bash
puppet agent -t
puppet agent -t
puppet resource pe_file_line ensure=present line='autosign = true' path=/etc/puppetlabs/puppet/puppet.conf
puppet config set autosign true --section master

systemctl start pe-puppetdb.service
systemctl start pe-postgresql.service
systemctl start pe-puppetserver.service	
systemctl start pe-console-services.service
systemctl start pe-bolt-server.service
systemctl start pe-nginx.service
systemctl start pe-orchestration-services.service