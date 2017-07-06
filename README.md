# HextupleO
This project has been created to deploy VM infrastructure on top of OpenStack that later can be consumed by new ephemeral TripleO OpenStack deployments.
It is all being developed with TripleO .. so both master OpenStack deployment as well as children OpenStack deployments are  done based on TripleO project .. hence the name hextupleO
This tool uses combination of ansible with shade libraries as well as some php and apache server for dashboard

Project is still under development. It's fully functional, but might still have bugs that I don't take resposibility of.
This is trully hacky approach to solving some real problems. Use at your own discretion.

<h1>Prerequisites:</h1>

Create a node (example RHEL VM) that will have access to RPM repositories, your master OpenStack deployment on both Public and Admin endpoints. <br>
The master OpenStack deployment have to be configured with nested-kvm enabled .. please reference this example if you don't know how to configure that:<br>
https://github.com/jonjozwiak/openstack/tree/master/director-examples/nested-virt-on-nova<br>
<br>
After the basic VM with RHEL7 is installed here are the steps that need to be done to complete the configuration:<br>
<br>
```
You need to import a special pxe boot image to your master openstack`in order to pxeboot overcloud nodes.
Here is how I have done it
wget https://github.com/OOsemka/hextupleo/raw/master/pxeboot.img
source overcloudrc  (of the master OpenStack)
openstack image create --disk-format raw --file pxeboot.img --public --container-format bare  pxeboot


yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm   #or whatever the latest link to epel is
yum install python-pip python-wheel ansible gcc python-devel
yum install python-neutronclient      # for whatever reason the neutron commands hasn't installed with shade 
pip install shade              

yum install httpd php
systemctl start httpd
systemctl enable httpd

setenforce 0     # unfortunately I have not figured out how to make this selinux friendly .. it's on the list to make it work
                 # you might want to disable selinux permanently for now
firewall-cmd --permanent --add-service http<br>
firewall-cmd  --reload<br>
```
<h1> HextupleO installation </h1>
<pre>
 
chmod 777 /usr/share/httpd  
cd /var/www/html/hextupleo
git clone https://github.com/OOsemka/hextupleo.git<br>

sudo -u apache ssh-keygen -t rsa
cp /usr/share/httpd/.ssh/id_rsa.pub nested-openstack/files/
</pre>
Let's change few config files:
<pre>
vi nested-openstack/vars/openstack_vars.yaml

    rhel_image: rhel7-raw  <-- this is the image that is going to be used for undercloud deployment
    pxe_image: pxeboot     <-- this is the image that will be used for all the overcloud nodes
    keypair: ansible       <-- don't need to change that
    flavor_undercloud: undercloud    <-- this is flavor that is going to be used for undercloud and needs to be pre-created
    flavor_controller: overcloud-controller    <-- this is flavor that is going to be used for controllers and needs to be pre-created
    flavor_compute: overcloud-compute    <-- this is flavor that is going to be used for compute and needs to be pre-created
    flavor_ceph: overcloud-ceph        <-- this is flavor that is going to be used for ceph and needs to be pre-created
    ceph_disk_count: 1         <-- don't need to change that 
    ceph_disk_size: 100        <-- ceph disk size
    cloud_admin: admin         <-- master openstack admin user 
    admin_password: changeme   <-- master openstack admin password 
    admin_project: admin       <-- master openstack admin tenant
    os_auth: http://192.168.1.2:5000/v2.0    <-- openstack public endpoint
    network_infra_ext: public    <-- don't need to change that 
    network_pxe: pxe             <-- don't need to change that 
    network_intapi: internalapi  <-- don't need to change that 
    network_tenant: tenant       <-- don't need to change that 
    network_storage: storage     <-- don't need to change that 
    network_storagemgmt: storagemgmt  <-- don't need to change that 
    
    
vi vars/networks


Here is the example file. Ultimately you want to define multiple external subnets that will be used by your openstack children. This file is your local database of what is being consumed by which openstack deployment. Also make sure IP addresses don't overlap - the network has also need to be pre-created in OpenStack master 

#id network   cidr           gateway    first ip    last ip
id1 vlan315 172.31.5.0/24 172.31.5.1 172.31.5.100 172.31.5.109 
id2 vlan315 172.31.5.0/24 172.31.5.1 172.31.5.110 172.31.5.119
id3 vlan315 172.31.5.0/24 172.31.5.1 172.31.5.120 172.31.5.129


vi nested-openstack/files/osp11/osp11.repo
vi nested-openstack/files/osp10/osp10.repo

These are repositories precreated with all OpenStack RH OSP rpms (you need to pre-create that first). Example:
[rhel-7-server-extras-rpms]
name=rhel-7-server-extras-rpms
baseurl=http://x.x.x.x/repos/rhel-7-server-extras-rpms/
enabled=1
gpgcheck=0
[rhel-7-server-openstack-11-devtools-rpms]
name=rhel-7-server-openstack-11-devtools-rpms
baseurl=http://x.x.x.x/repos/rhel-7-server-openstack-11-devtools-rpms/
enabled=1
gpgcheck=0
[rhel-7-server-openstack-11-optools-rpms]
name=rhel-7-server-openstack-11-optools-rpms
baseurl=http://x.x.x.x/repos/rhel-7-server-openstack-11-optools-rpms/
enabled=1
gpgcheck=0
[rhel-7-server-openstack-11-rpms]
name=rhel-7-server-openstack-11-rpms
baseurl=http://x.x.x.x/repos/rhel-7-server-openstack-11-rpms/
enabled=1
gpgcheck=0
[rhel-7-server-openstack-11-tools-rpms]
name=rhel-7-server-openstack-11-tools-rpms
baseurl=http://x.x.x.x/repos/rhel-7-server-openstack-11-tools-rpms/
enabled=1
gpgcheck=0
[rhel-7-server-optional-rpms]
name=rhel-7-server-optional-rpms
baseurl=http://x.x.x.x/repos/rhel-7-server-optional-rpms/
enabled=1
gpgcheck=0
[rhel-7-server-rh-common-rpms]
name=rhel-7-server-rh-common-rpms
baseurl=http://x.x.x.x/repos/rhel-7-server-rh-common-rpms/
enabled=1
gpgcheck=0
[rhel-7-server-rhceph-2-mon-rpms]
name=rhel-7-server-rhceph-2-mon-rpms
baseurl=http://x.x.x.x/repos/rhel-7-server-rhceph-2-mon-rpms/
enabled=1
gpgcheck=0
[rhel-7-server-rhceph-2-osd-rpms]
name=rhel-7-server-rhceph-2-osd-rpms
baseurl=http://x.x.x.x/repos/rhel-7-server-rhceph-2-osd-rpms/
enabled=1
gpgcheck=0
[rhel-7-server-rhceph-2-tools-rpms]
name=rhel-7-server-rhceph-2-tools-rpms
baseurl=http://x.x.x.x/repos/rhel-7-server-rhceph-2-tools-rpms/
enabled=1
gpgcheck=0
[rhel-7-server-rpms]
name=rhel-7-server-rpms
baseurl=http://x.x.x.x/repos/rhel-7-server-rpms/
enabled=1
gpgcheck=0


</pre>
