# HextupleO 2.0
This project has been created to deploy VM infrastructure on top of OpenStack that later can be consumed by new ephemeral TripleO OpenStack deployments.
It is all being developed with TripleO .. so both master OpenStack deployment as well as children OpenStack deployments are  done based on TripleO project .. hence the name hextupleO
This tool uses combination of ansible with shade libraries as well as some php and apache server for dashboard (alternatively ansible core or ansible tower can be used).

HextupleO Demo:
https://www.youtube.com/embed/NPZon911V5A

Project is still under development. It's fully functional, but might still have bugs that I don't take responsibility of. Use at your own discretion.

Check-out for trello board tracking new feature and progress overall:
https://trello.com/b/Hhz1A3hl/hextupleo-project

<h1> How to Deploy </h1>

This project has been recently enhanced with ability to automatically deploy wit following front ends:<br>
- <b>core</b> (default) - uses ansible core and all the nested openstack deployments will occur by executing ansible-playbook -e variables.yml playbook.yml<br>
- <b>http</b> - uses custom php based web portal for executing nested openstacks - one advantage is ability to track all the deployments in on place <br>
- <b>tower</b> - uses ansible tower front end for nested openstack execution - can also be further integrated with Cloudforms <br>

<h1>Prerequisites:</h1>
<br>
- RHEL7 VM connected to repos <br>
- Nested KVM enabled on Openstack compute <br>
- Jumbo Frame support for the Tenant Network in Overcloud <br>
- Local rpm repository for OSP and Ceph<br>
- 2x Provider Networks in Overcloud (external)<br>

<br>
Create a node (example RHEL VM) that will have access to RPM repositories, your master OpenStack deployment on both Public and Admin endpoints.<br>
This could look the same as your undercloud 1x External net + 1 PXE net <br>
RHEL7 VM should be connected to RH repos - preferable latest OSP repos.<br>
<br>
<br>
The master OpenStack deployment have to be configured with nested-kvm enabled .. please reference this example if you don't know how to configure that:<br>
https://github.com/jonjozwiak/openstack/tree/master/director-examples/nested-virt-on-nova<br>
<br>
<br>
Setting up Jumbo frames for the Overcloud has been described in here: <br>
https://access.redhat.com/solutions/2521041<br>
<br>
<br>
Build a local repository that includes following repos for all OSP version that you are planning to deploy:<br>
[rhel-7-server-extras-rpms]<br>
[rhel-7-server-openstack-11-devtools-rpms]<br>
[rhel-7-server-openstack-11-optools-rpms]<br>
[rhel-7-server-openstack-11-rpms]<br>
[rhel-7-server-openstack-11-tools-rpms]<br>
[rhel-7-server-optional-rpms]<br>
[rhel-7-server-rh-common-rpms]<br>
[rhel-7-server-rhceph-2-mon-rpms]<br>
[rhel-7-server-rhceph-2-osd-rpms]<br>
[rhel-7-server-rhceph-2-tools-rpms]<br>
[rhel-7-server-rpms]<br>
<br>
You might want to include OSP10 as well.<br>
<br>
<br>
The two provider networks are going to be used for 2 roles:<br>
- providing external IP to nested undercloud - and in the future for any supporting roles that require external ip like Cloudforms, Ansible Tower, Satellite etc.<br>
- External IP and Floating IPs to nested Overcloud Controllers<br>
<br>
Right not at least the first External network should also be configured with 'Externel' neutron flag enabled <br>

```
<h1> HextupleO installation </h1>
<pre>

ssh-keygen -t rsa
ssh-copy-id localhost
yum -y install ansible git
git clone https://github.com/OOsemka/hextupleo.git
cd hextupleo
vi vars/install-vars.yml

</pre>
Let's ensure variables is config files match our environment:
<pre>
    # Overcloud Admin User. Can be typically found inside overcloudrc file
    cloud_admin: admin
    # Overcloud Admin User password. Can be typically found inside overcloudrc file
    admin_password: Passw0rd
    # Overcloud Admin Tenant. Can be typically found inside overcloudrc file
    admin_project: admin
    # Overcloud public keystone endpoint. Can be typically found inside overcloudrc file
    os_auth: https://openstack.home.lab:13000/v2.0
    # NTP server that will be reachable in nested overcloud
    ntp_server: 172.31.8.1
    # DNS server that will be reachable from nested overcloud
    dns_server: 172.31.8.1
    # First out of 2 external networks. This one is used mainly for undercloud and supporting roles
    external_net: provider2
    # Pre-build local rpm repository to OSP and Ceph
    repo_server: http://172.31.8.1/repos/
    # Specify how do you want to consume hextupleO - options are (tower, core, http) - core default
    deployment_type: tower

    # Flavors used for nested OpenStack roles
    flavors:
      undercloud:
        name: undercloud
        ram: 16384
        disk: 100
        vcpu: 4
      controller:
        name: overcloud-controller
        ram: 12288
        disk: 60
        vcpu: 2
      compute:
        name: overcloud-compute
        ram: 12288
        disk: 60
        vcpu: 4
      ceph:
        name: overcloud-ceph
        ram: 4096
        disk: 50
        vcpu: 2
      hci:
        name: overcloud-hci
        ram: 16384
        disk: 60
        vcpu: 4
      rhel-pre:
        name: rhel-small
        ram: 4096
        disk: 10
        vcpu: 2
</pre>    
<br>
Finally let's configure the second provider network that will be consumed by Nested OpenStack controllers for External APIs and Floating IPs: <br>    
<pre>
# cat files/networks.csv 
#id,network,cidr,gateway,firstip,lastip,cf1,reservedby
id1,provider1,172.31.6.0/24,172.31.6.254,172.31.6.100,172.31.6.109
id2,provider1,172.31.6.0/24,172.31.6.254,172.31.6.110,172.31.6.119
id3,provider1,172.31.6.0/24,172.31.6.254,172.31.6.120,172.31.6.129
id4,provider1,172.31.6.0/24,172.31.6.254,172.31.6.130,172.31.6.139
id5,provider1,172.31.6.0/24,172.31.6.254,172.31.6.140,172.31.6.149
id6,provider1,172.31.6.0/24,172.31.6.254,172.31.6.150,172.31.6.159
</pre>
<br>
First column is a primary key of this local file database. It has to start with "id" and end with the number <br>
Second column is a pre-defined external/provider network that he been already created in OpenStack (master overcloud)<br>
Next we split large /24 network into smaller chunks that will be used to separate nested OpenStacks. <br>
Please ensure network.csv stays in files directory and the field are delimited by comma (,)<br>
<br>
<br>
NOTE: If you decided to deploy it under Tower, please ensure vars/tower_cli.cfg has your Tower credentials<br> 
<br>
<br>
We should be able to execute installation playbook:<br>
<pre>
ansible-playbook install.yml
</pre>


<h1> How to use it </h1>
Now depends on how you set the installation parameter, you could either start deploying nested openstacks in 3 different ways:<br>
 - via ansible core (playbook from cli)<br>
 - via custom http webform (http://localhost/hextupleO)<br>
 - via ansible Tower<br>
<br>
<b>For core:</b><br>
Edit deploy-vars.yml file with # of node types you want to deploy in nested OpenStack and execute:<br>
ansible-playbook htplO-build-all.yml -e @deploy-vars.yml<br>
<br>
<b>For http:</b><br>
Open your web browser to a RHEL server external IP address with directory /hextupleO and decide how to build your nested OpenStack (http://external-ip//hextupleO)<br>
<br>
<b>For Tower:</b><br>
Log on to Tower Web-ui and the new TEmplates for creating and destroying nested OpenStack should be already there.<br>
<br>
<br>
Enjoy!
