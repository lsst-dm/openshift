# openshift CentOS 7 install

These are modified instructions from:
https://gist.github.com/boube/76660589e208ffe6032a#file-qd-openshift-origin-centos7-md

These instructions are how to get OpenShift 3.6 up and running on OpenStack.
There may be some extra or (or missing!)  steps in here, and if you discover
those, plus update this readme with what you've discovered.

## Installation Notes

The following is specific to OpenShift 3.6, and Centos 7.  A couple of things
that may change out from under you:

1. The OpenShift ansible archive is updated frequently, even the labeled
branches.  I presume this is because of bug fixes;  Not sure why they're not
doing this in x.x release versions though.  Just something to keep in mind
while updating.  If, for some reason, you decide to install from that main
branch of openshift-ansible, the /etc/ansible/hosts file may have to be
modified because there could be some incompatibilities.
2. Step 4 installs to epel-release-7-10.noarch.rpm  If you aren't able to
install that particular version, check that download site to see if they've 
updated to epel-release-7-XYZ.noarch.rpm (XYZ being some future rev).  This
happened during testing, so be aware that old versions don't hang around
that directory.

## Installation procedure


1. Create all nodes on OpenShift.  The baseline I an image I used from CentOS 7.2, upgrade to 7.3 as part of the instructions below.
.. Make a note of all internal IPs created
2. Create volumes for each of the nodes, and make a note of the volume names
on each node.  It happens that the dev names were all /dev/vdb when I created
them for what I was doing.

### Install dependencies:

#### On Master:

1. Edit /etc/hosts to add all internal IPs you've created.

2. `sh-4.2# yum -y update`

3. `sh-4.2# yum -y install vim wget git net-tools bind-utils iptables-services bridge-utils bash-completion pyOpenSSL docker`

4. `sh-4.2# yum -y install https://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-10.noarch.rpm`

5. `sh-4.2# sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo ; yum -y --enablerepo=epel install ansible`

6. `sh-4.2# cd $HOME`
7. `sh-4.2# git clone https://github.com/openshift/openshift-ansible`
8. `sh-4.2# cd openshift-ansible`
9. `sh-4.2# git checkout release-3.6`

10. Edit /etc/sysconfig/docker-storage-setup and substitute the correct device name for /dev/vdb below
```
DEVS=/dev/vdb
VG=docker-vg
```

11. `sh-4.2# docker-storage-setup`

12. `sh-4.2# sed "s/OPTIONS=.*/OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0\/16'/g"  -i /etc/sysconfig/docker`

13. `sh-4.2# systemctl enable docker`
14. `sh-4.2# systemctl start docker`

#### On each worker node:

15. Edit /etc/hosts to add all internal IPs you've created.

16. `sh-4.2# yum -y update`
17. `sh-4.2# yum -y install vim wget git net-tools bind-utils iptables-services bridge-utils bash-completion pyOpenSSL docker`
18. Edit /etc/sysconfig/docker-storage-setup and substitute the correct device name for /dev/vdb below
```
DEVS=/dev/vdb
VG=docker-vg
```

19. `sh-4.2# docker-storage-setup`
20. `sh-4.2# sed "s/OPTIONS=.*/OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0\/16'/g"  -i /etc/sysconfig/docker`
21. `sh-4.2# systemctl enable docker`
22. `sh-4.2# systemctl start docker`


### After dependencies have been installed:

23. Enable SSH root login on ALL nodes, including the master.  This step is
required to run ansible.

24. Edit /etc/ansible/hosts and add the following. (see note below!)

```
[OSEv3:children]
masters
nodes

[OSEv3:vars]
ansible_ssh_user=root
deployment_type=origin

[masters]
masterhost openshift_ip=172.16.1.198 openshift_public_ip=172.16.1.198 openshift_public_hostname=masterhost


[etcd]
masterhost

[nodes]
masterhost openshift_ip=172.16.1.198 openshift_public_ip=172.16.1.198 openshift_node_labels="{'region': 'infra', 'zone': 'default'}" openshift_public_hostname=masterhost openshift_schedulable=true
node-1 openshift_ip=172.16.1.200 openshift_public_ip=172.16.1.200 openshift_node_labels="{'region': 'infra', 'zone': 'ldf'}" openshift_public_hostname=node-1
node-2 openshift_ip=172.16.1.201 openshift_public_ip=172.16.1.201 openshift_node_labels="{'region': 'infra', 'zone': 'ldf'}" openshift_public_hostname=node-2
```

### Note
In this example file, there are three targets:  masterhost, node-1 and node-2.
You need to substitute "masterhost" the names of your master host target,
"node-1" and "node-2" with each of your worker nodes.  (Adding more worker nodes as required).
The IP addresses for each of these targets must match the IP addresses you
noted in Step 1.

25. Run the following command:
`sh-4.2# ansible-playbook ~/openshift-ansible/playbooks/byo/config.yml`

Note that this takes quite a while to run, and may look like it's stuck
at some points while it verifies that services are up and running.

26. When this is all completed, you should be able to run:
`sh-4.2# oc get nodes`

and see something like:
```
sh-4.2# oc get nodes
NAME           STATUS    AGE       VERSION
172.16.1.122   Ready     1d        v1.6.1+5115d708d7
172.16.1.123   Ready     1d        v1.6.1+5115d708d7
172.16.1.125   Ready     1d        v1.6.1+5115d708d7
```

and
`sh-4.2# oc get pods`

should show something like:

```
sh-4.2# oc get pods
NAME                       READY     STATUS    RESTARTS   AGE
docker-registry-1-2lhk6    1/1       Running   1          1d
registry-console-1-v8s3g   1/1       Running   0          1d
router-1-dlt7l             1/1       Running   0          1d
router-1-kj85l             1/1       Running   0          1d
router-1-ld6n9             1/1       Running   0          1d
```
