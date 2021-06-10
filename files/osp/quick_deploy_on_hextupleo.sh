#!/bin/bash

# This was created in the even you needed to quickly deploy a vanilla OSP on Hextuple-O to
# perform a demo.
#
# First, check eth3 and make sure it has the IP of 10.60.0.1, if not, reboot Director
# at some point and it will fix it.  It has to do with the way the VM is created initially.
# You can use this 10.60.0.0/24 network as provider0 to expose as Floating IP addresses or
# even to demonstrate provider networks.
#
# To use this script, you will need to set the follwoing to your Red Hat Registry information.
# You can create/get this information here:  https://access.redhat.com/terms-based-registry/

ACCOUNT_NAME="783....|ds-o........"
TOKEN="eyJhbGciO..........................................Hextuple-O..FTW!!!!..................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................."

# This is to set the root password in overcloud-full.qcow2 in case you need to
# do some troubleshooting.

OVERCLOUD_ROOT_PASSWORD="Redhat01"

OSP_VERSION=$(yum repolist | grep -o openstack-[0-9][0-6] | sort -u | awk -F- '{print $2}')

if [[ ! -z "$(echo ${OSP_VERSION} | sed 's/[0-9][0-9]*//g')" ]]
then
  echo "Could not determine OSP version."
  exit 1
fi

INSTALLER=dnf

if [[ ! -z "$(grep -i 'release 7' /etc/redhat-release)" ]]
then
  INSTALLER=yum
fi

function setup_base_install() 
{
  for FILE in deploy.sh instackenv.json instackenv.yaml prepare_container_images.sh
  do
        if [[ -f ~/GoodieBag/${FILE} ]]
        then
  	  cp ~/GoodieBag/${FILE} ~/${FILE}
        fi
  done
  
  sudo yum update -y
  sudo ${INSTALLER} install -y tmux ceph-ansible
  if [[ ${OSP_VERSION} -le 14 ]]
  then
    sudo ${INSTALLER} install -y python-tripleoclient ceph-ansible tmux
  else
    sudo ${INSTALLER} install -y python3-tripleoclient
  fi

  if [[ -f ~/prepare_container_images.sh ]]
  then 
    source ~/prepare_container_images.sh
  
cat <<EOF>>~/templates/containers-prepare-parameter.yaml
  ContainerImageRegistryCredentials:
    registry.redhat.io:
      ${ACCOUNT_NAME}: ${TOKEN}
EOF
  fi
}  

function undercloud_install()
{
  openstack undercloud install

  if [[ $? -eq 0 ]]
  then
    source ~/stackrc
    NAMESERVER=$(egrep -i ^nameserver /etc/resolv.conf | head -1 | awk '{print $NF}')
    openstack subnet set --dns-nameserver ${NAMESERVER}  ctlplane-subnet
  else
    echo "ERROR: Undercloud deployment failed. Investigate!"
    exit 1
  fi
}

function undercloud_install_images()
{
  sudo ${INSTALLER} install rhosp-director-images rhosp-director-images-ipa -y
  
  cd ~/images
  for i in /usr/share/rhosp-director-images/overcloud-full-latest-*.tar /usr/share/rhosp-director-images/ironic-python-agent-latest-*.tar
  do
  	tar -xvf $i
  done
  
  virt-customize -a overcloud-full.qcow2 --root-password password:${OVERCLOUD_ROOT_PASSWORD}
  
  source ~/stackrc
  
  openstack overcloud image upload --image-path /home/stack/images/
  if [[ $? -eq 0 ]]
  then
    if [[ $(openstack image list -f value | wc -l) -le 2 ]]
    then
      echo "ERROR: Image upload failed! Glance doesn't look right. Investigate!"
      openstack image list
      exit 1
    fi
    
    if [[ ${OSP_VERSION} -ge 15 ]]
    then
      if [[ $(ls -l /var/lib/ironic/httpboot | egrep '(agent.kernel|agent.ramdisk|boot.ipxe|inspector.ipxe)' | wc -l) -ne 4 ]]
      then
        echo "ERROR: Image upload failed! The httpboot directory doesn't look right. Investigate!"
        ls -l /var/lib/ironic/httpboot
        exit 1
      fi
    fi
  else
    echo "ERROR: Image upload failed! Investigate!"
    exit 1
  fi
}

function undercloud_add_overcloud_nodes()
{
  source ~/stackrc

  IMPORT_FILE=$(ls ~/instackenv.*)

  openstack overcloud node import ${IMPORT_FILE}
  
  if [[ -z "$(openstack baremetal node list -c UUID -f value)" ]]
  then
  	echo "No nodes found."
  	exit 1
  else
    openstack overcloud node introspect --all-manageable --provide
  fi

  if [[ ! -z "$(openstack baremetal node list -f value | egrep -v ' available ')" ]]
  then
    echo "ERROR: Error importing nodes.  Investigate!"
    openstack baremetal node list
    exit 1
  fi
}

function overcloud_update_templates()
{
  sed -n '/The content of the CA cert goes here/q;p' /usr/share/openstack-tripleo-heat-templates/environments/ssl/inject-trust-anchor-hiera.yaml >~/templates/inject-trust-anchor-hiera.yaml
  sed -i "s/first-ca-name/$(hostname -s)/g" ~/templates/inject-trust-anchor-hiera.yaml
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ {print "        "$0}' /etc/pki/ca-trust/source/anchors/cm-local-ca.pem >>~/templates/inject-trust-anchor-hiera.yaml
  sed -i '/inject-trust-anchor-hiera.yaml/d' ~/deploy.sh
  sed -i '/^     --log-file /i\     -e templates/inject-trust-anchor-hiera.yaml \\' ~/deploy.sh
}


setup_base_install
undercloud_install
undercloud_install_images
undercloud_add_overcloud_nodes
overcloud_update_templates

echo "You are ready to deploy.  Execute ~/deploy.sh.  You may want to do this in a tmux session. (Which has been installed for you. You're welcome.)"
