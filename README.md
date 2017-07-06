# hextupleo
This project has been created to deploy VM infrastructure on top of OpenStack that later can be consumed by new ephemeral TripleO OpenStack deployments.
It is all being developed with TripleO .. so both master OpenStack deployment as well as children OpenStack deployments are or done based on TrieplO project .. hence the name hextupleO
This tool uses combination of ansible with shade libraries as well as some php and apache server for dashboard


<h1>Prerequisites:</h1>

Create a node (example RHEL VM) that will have access to RPM repositories, your master OpenStack deployment on both Public and Admin endpoints. <br>
The master OpenStack deployment have to be configured with nested-kvm enabled .. please reference this example if you don't know how to configure that:<br>
https://github.com/jonjozwiak/openstack/tree/master/director-examples/nested-virt-on-nova<br>
<br>
After the basic VM with RHEL7 is installed here are the steps that need to be done to complete the configuration:<br>
<br>
```
yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm   #or whatever the latest link to epel is<br>
yum install python-pip python-wheel ansible gcc python-devel<br>
yum install python-neutronclient      # for whatever reason the neutron commands hasn't installed with shade <br>
pip install shade              <br>
<br>
yum install httpd php<br>
systemctl start httpd<br>
systemctl enable httpd<br>
<br>
setenforce 0     # unfortunately I have not figured out how to make this selinux friendly .. it's on the list to make it work<br>
                 # you might want to disable selinux permanently for now<br>
firewall-cmd --permanent --add-service http<br>
firewall-cmd  --reload<br>
<br>
<br>
```
<h1> HextupleO installation </h1>
 <br>
```
 <br>
chmod 777 /usr/share/httpd  <br>
cd /var/www/html/hextupleo<br>
git clone https://github.com/OOsemka/hextupleo.git<br>
<br>
sudo -u apache ssh-keygen -t rsa<br>
cp /usr/share/httpd/.ssh/id_rsa.pub nested-openstack/files/<br>
```
