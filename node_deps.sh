yum -y update 
yum -y install vim  wget git net-tools bind-utils iptables-services bridge-utils bash-completion pyOpenSSL docker
cat <<EOF > /etc/sysconfig/docker-storage-setup
DEVS=/dev/vdb
VG=docker-vg
EOF
docker-storage-setup
sed "s/OPTIONS=.*/OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0\/16'/g"  -i /etc/sysconfig/docker
systemctl enable docker
systemctl start docker
