docker run --privileged --name pe -v /sys/fs/cgroup:/sys/fs/cgroup:ro -p 443:443 -h pe.example.com -it puppet-enterprise:2019.8.1-7 
