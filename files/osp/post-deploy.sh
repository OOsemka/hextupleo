#!/bin/bash

sudo yum -y install rhel-guest-image-7.noarch
cp /usr/share/rhel-guest-image-7/rhel-guest-image-7.2-20160302.0.x86_64.qcow2 /home/stack
virt-customize -a /home/stack/rhel-guest-image-7.2-20160302.0.x86_64.qcow2 --root-password password:Passw0rd

rcfile=`ls *rc | grep -v stackrc`


source ~/$rcfile
openstack image create --file /home/stack/rhel-guest-image-7.2-20160302.0.x86_64.qcow2 --public rhel7

openstack flavor create --ram 1024 --disk 10 --vcpus 1 small
openstack keypair create --public-key /home/stack/.ssh/id_rsa.pub undercloud

nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0



openstack network create --internal internal
openstack subnet create --dhcp --network internal --dns-nameserver 10.9.71.7 --subnet-range 192.168.100.0/24 internal-sub

