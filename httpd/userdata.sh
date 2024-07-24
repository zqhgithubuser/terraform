#!/bin/bash
yum install -y httpd amazon-efs-utils
pip3 install botocore
echo "${efs_id}:/ /var/www/html efs tls,_netdev 0 0" >> /etc/fstab
while ! (echo > /dev/tcp/${efs_id}.efs.${region}.amazonaws.com/2049) >/dev/null 2>&1; do sleep 5; done
mount -a -t efs
chown -R apache:apache /var/www/html
echo "Hello, world" > /var/www/html/index.html
systemctl enable httpd
systemctl start httpd
