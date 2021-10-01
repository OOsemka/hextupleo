#!/bin/bash
#############################
# This is not fully dynamic file and it might have not been populated with all right information. This is a template. You might still want to verify this is what you want before executing it
##############################

source ~/stackrc
cd ~/
time openstack overcloud deploy --templates --stack chrisj-dcn2 \
     -n templates/network_data_spine_leaf.yaml \
     -r templates/dcn2/dcn2_roles.yaml \
     -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
     -e /usr/share/openstack-tripleo-heat-templates/environments/network-environment.yaml \
     -e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-ovs.yaml \
     -e /usr/share/openstack-tripleo-heat-templates/environments/nova-az-config.yaml \
     -e /usr/share/openstack-tripleo-heat-templates/environments/dcn.yaml \
     -e templates/dcn2/site-name.yaml \
     -e dcn-common/central-export.yaml \
     -e templates/inject-trust-anchor-hiera.yaml \
     -e templates/containers-prepare-parameter.yaml \
     -e templates/dcn2/node-info.yaml \
     -e templates/network-environment.yaml \
     -e templates/spine-leaf-ctlplane.yaml \
     -e templates/spine-leaf-vips.yaml \
     --log-file chrisj-dcn2_deployment.log \
     --ntp-server 10.10.0.10

