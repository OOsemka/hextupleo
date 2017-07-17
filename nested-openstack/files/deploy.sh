#!/bin/bash
#############################
# This is not dynamic file and it hasn't been populated with correct information. This is a template. You might still want to verify this is what you want before executing it
##############################

source ~/stackrc
cd ~/
time openstack overcloud deploy --templates --stack hextupleO \
     --ntp-server 10.9.65.6 \
     --control-flavor control --control-scale 3 \
     --compute-flavor compute --compute-scale 3 \
     --ceph-storage-flavor ceph-storage --ceph-storage-scale 0 \
     -e templates/network-environment.yaml \
     -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml 

     #if ceph has been configured you might consider adding following pre-defined extension (again verify it's what you want):
     #-e templates/storage-environment.yaml \

     # for hyperconverged (hci) nodes you could use this file
     #-e /usr/share/openstack-tripleo-heat-templates/environments/hyperconverged-ceph.yaml
     #-e templates/hci-compute.yaml 

