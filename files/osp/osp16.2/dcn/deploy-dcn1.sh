#!/bin/bash
#############################
# This is not fully dynamic file and it might have not been populated with all right information. This is a template. You might still want to verify this is what you want before executing it
##############################

source ~/stackrc
cd ~/
time openstack overcloud deploy --templates --stack chrisj-dcn1 \
     -n templates/network_data_spine_leaf.yaml \
     -r templates/dcn1/dcn1_roles.yaml \
     -e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml \
     -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
     -e /usr/share/openstack-tripleo-heat-templates/environments/network-environment.yaml \
     -e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-ovs.yaml \
     -e /usr/share/openstack-tripleo-heat-templates/environments/dcn-hci.yaml \
     -e templates/host-memory.yaml \
     -e templates/dcn1/site-name.yaml \
     -e dcn-common/central-export.yaml \
     -e dcn-common/central_ceph_external.yaml \
     -e templates/dcn1/tuning.yaml \
     -e templates/dcn1/glance.yaml \
     -e templates/inject-trust-anchor-hiera.yaml \
     -e templates/containers-prepare-parameter.yaml \
     -e templates/dcn1/dcn1-images-env.yaml \
     -e templates/dcn1/node-info.yaml \
     -e templates/dcn1/ceph.yaml \
     -e templates/network-environment.yaml \
     -e templates/spine-leaf-ctlplane.yaml \
     -e templates/spine-leaf-vips.yaml \
     --log-file chrisj-dcn_deployment.log \
     --ntp-server 10.10.0.10

     # If you're going to use SSL, you will need to copy over this file and make
     # necessary adjustments
     #-e /home/stack/templates/inject-trust-anchor-hiera.yaml \
     # the one below came from osp14, but has not been adapted to osp15 or osp16 yet
     #-e templates/fixed-ip-vips.yaml \

