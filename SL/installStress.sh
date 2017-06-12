#!/bin/sh
sudo wget http://dl.fedoraproject.org/pub/epel/6/x86_64/stress-1.0.4-4.el6.x86_64.rpm
sudo yum -y install stress-1.0.4-4.el6.x86_64.rpm 
stress -c 1 -m 1 --vm-bytes 300M > /dev/null 2>&1 &
