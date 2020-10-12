############################################################
# Dockerfile voor een base image welke gebruikt kan worden
# voor andere dockerfiles
# Based on CENTOS7
############################################################

# Set the base image to CENTOS7
FROM centos:centos7

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

WORKDIR /root

# Update the repository sources list and install tools
RUN yum -y update && yum -y install crontabs wget git unzip net-tools systemd gettext glibc unzip python3 diffutils sudo && yum clean all

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*;\
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /lib/systemd/system/anaconda.target.wants/*;

COPY start-puppet.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/start-puppet.sh

VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]
