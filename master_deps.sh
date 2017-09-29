#!/bin/sh
yum -y update 
yum -y install vim  wget git net-tools bind-utils iptables-services bridge-utils bash-completion pyOpenSSL docker 
yum -y install https://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-10.noarch.rpm 
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo ; yum -y --enablerepo=epel install ansible
git clone https://github.com/openshift/openshift-ansible
cat <<EOF > /etc/sysconfig/docker-storage-setup
DEVS=/dev/vdb
VG=docker-vg
EOF
docker-storage-setup
sed "s/OPTIONS=.*/OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0\/16'/g"  -i /etc/sysconfig/docker
systemctl enable docker
systemctl start docker
