#
# Docker installation
#
class profile::docker {

    yumrepo { 'docker':
      ensure   => 'present',
      descr    => 'Docker Community Edition repository for CentOS',
      baseurl  => 'https://download.docker.com/linux/centos/8/x86_64/stable',
      enabled  => 'true',
      gpgcheck => 'false'
    }
    $install = [ 'docker-ce' ]
    package { $install:
        ensure => present
    }
    service { 'docker':
        ensure => 'running',
    }
    file { '/root/.docker':
        ensure => 'directory',
        mode   => '0750',
    }
    file { '/etc/systemd/system/docker.service.d/':
        ensure => 'directory',
        mode   => '0750',
    }
    exec { 'Docker-compose':
        command => '/usr/bin/curl -L https://github.com/docker/compose/releases/download/1.25.4/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && chmod 755 /usr/local/bin/docker-compose',
        creates => '/usr/local/bin/docker-compose'
    }
}
