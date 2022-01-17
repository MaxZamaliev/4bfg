#!/bin/bash

#/etc/init.d/supervisor start

mkdir /var/run/sshd
chmod 755 /var/run/sshd
/usr/sbin/sshd -D
