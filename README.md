# nestedEsxiVcenter

## Goal

This Infrastructure as code will deploy a nested ESXi/vCenter/NSXT/Avi (on the top of vCenter environment).

## Use cases

### Single VDS - if vcenter.dvs.single_vds == true
In this use case, a single vds switch is configured in the nested vCenter with three port groups:
- Management
- Vmotion
- VSAN

The following port groups are configured with a specific VLAN ID:
- vcenter.dvs.portgroup.management.name with VLAN id vcenter.dvs.portgroup.management.vlan 
- vcenter.dvs.portgroup.VMotion.name with VLAN id vcenter.dvs.portgroup.VMotion.vlan
- vcenter.dvs.portgroup.VSAN.name with VLAN id vcenter.dvs.portgroup.VSAN.vlan

Two "physical" uplink NICs (per ESXi host) are connected to this single VDS.
These two NICs are connected to the underlay vCenter network defined in underlay_vcenter.network (leveraging 802.1q).

### Multiple VDS - if vcenter.dvs.single_vds == false
In this use case, multiple vds switches are configured in the nested vCenter:
- dvs-0 with a port group called vcenter.dvs.portgroup.management.name and a port group called "vcenter.dvs.portgroup.management.name"-vmk - connected to a "physical" uplink to the underlay network (vcenter_underlay.networks.management)
- dvs-1-VMotion with a port group called vcenter.dvs.portgroup.management.VMotion.name - connected to a "physical" uplink to the underlay network (vcenter_underlay.vmotion.management)
- dvs-2-VSAN with a port group called vcenter.dvs.portgroup.management.VSAN.name - connected to a "physical" uplink to the underlay network (vcenter_underlay.vsan.management)
Each VDS switch is connected to one "physical" uplink NIC will be connected to the underlay vCenter network defined in underlay_vcenter.network (leveraging 802.1q).

### DNS NTP Server creation - if dns_ntp.create == true

## prerequisites on the underlay environment
- vCenter underlay version:
```
6.7.0
```

## prerequisites on the Linux machine
- OS Version
```
18.04.2 LTS (Bionic Beaver)
```
- TF Version
```
Terraform v0.14.8
+ provider registry.terraform.io/hashicorp/dns v3.2.1
+ provider registry.terraform.io/hashicorp/local v2.1.0
+ provider registry.terraform.io/hashicorp/null v3.1.0
+ provider registry.terraform.io/hashicorp/template v2.2.0
+ provider registry.terraform.io/hashicorp/vsphere v2.0.2

Your version of Terraform is out of date! The latest version
is 1.0.4. You can update by downloading from https://www.terraform.io/downloads.html
```
- Ansible Version
```
ansible --version
[DEPRECATION WARNING]: Ansible will require Python 3.8 or newer on the controller starting with Ansible 2.12. Current
version: 2.7.17 (default, Feb 27 2021, 15:10:58) [GCC 7.5.0]. This feature will be removed from ansible-core in version
 2.12. Deprecation warnings can be disabled by setting deprecation_warnings=False in ansible.cfg.
/home/ubuntu/.local/lib/python2.7/site-packages/ansible/parsing/vault/__init__.py:44: CryptographyDeprecationWarning: Python 2 is no longer supported by the Python core team. Support for it is now deprecated in cryptography, and will be removed in a future release.
  from cryptography.exceptions import InvalidSignature
ansible [core 2.11.3]
  config file = /etc/ansible/ansible.cfg
  configured module search path = [u'/home/ubuntu/.ansible/plugins/modules', u'/usr/share/ansible/plugins/modules']
  ansible python module location = /home/ubuntu/.local/lib/python2.7/site-packages/ansible
  ansible collection location = /home/ubuntu/.ansible/collections:/usr/share/ansible/collections
  executable location = /home/ubuntu/.local/bin/ansible
  python version = 2.7.17 (default, Feb 27 2021, 15:10:58) [GCC 7.5.0]
  jinja version = 2.11.2
  libyaml = False
```
- govc Version
```shell
wget https://github.com/vmware/govmomi/releases/download/v0.24.0/govc_linux_amd64.gz
gunzip govc_linux_amd64.gz
mv govc_linux_amd64 govc
chmod +x govc
```

```
govc v0.24.0
```
- jq version
```shell
sudo apt install -y jq
```

```
jq - commandline JSON processor [version 1.5-1-a5b5cbe]
```


## variables

### non sensitive variables

All the non sensitive variables are stored in variables.json


### sensitive variables

All the sensitive variables are stored in environment variables as below:

```bash
export TF_VAR_esxi_root_password=******              # Nested ESXi root password
export TF_VAR_vsphere_username=******                # Underlay vCenter username
export TF_VAR_vsphere_password=******                # Underlay vCenter password
export TF_VAR_bind_password=******                   # Bind password
export TF_VAR_vcenter_password=******                # Overlay vCenter admin password
export TF_VAR_nsx_password=******                    # NSX admin password
export TF_VAR_nsx_license=******                     # NSX license
export TF_VAR_avi_password=******                    # AVI admin password
export TF_VAR_avi_old_password=******                # AVI old passwors
```

## start the script (create the infra)

```shell
git clone https://github.com/tacobayle/tfNestedEsxiVcenterMultipleVdsNsxAvi ; cd tfNestedEsxiVcenterMultipleVdsNsxAvi ; /bin/bash apply.sh
Cloning into 'tfNestedEsxiVcenterMultipleVdsNsxAvi'...
remote: Enumerating objects: 293, done.
remote: Counting objects: 100% (293/293), done.
remote: Compressing objects: 100% (195/195), done.
remote: Total 293 (delta 130), reused 250 (delta 87), pack-reused 0
Receiving objects: 100% (293/293), 2.05 MiB | 2.30 MiB/s, done.
Resolving deltas: 100% (130/130), done.
-----------------------------------------------------
Build of a folder on the underlay infrastructure - This should take less than a minute
Starting timestamp: Thu Mar 31 14:58:15 UTC 2022
Ending timestamp: Thu Mar 31 14:58:19 UTC 2022
-----------------------------------------------------
Build of a DNS/NTP server on the underlay infrastructure - This should take less than 5 minutes
Starting timestamp: Thu Mar 31 14:58:19 UTC 2022
Ending timestamp: Thu Mar 31 15:01:28 UTC 2022
-----------------------------------------------------
Build of an external GW server on the underlay infrastructure - This should take less than 5 minutes
Starting timestamp: Thu Mar 31 15:01:28 UTC 2022
Ending timestamp: Thu Mar 31 15:07:04 UTC 2022
-----------------------------------------------------
Build of the nested ESXi/vCenter infrastructure - This should take less than 45 minutes
Starting timestamp: Thu Mar 31 15:07:04 UTC 2022
Ending timestamp: Thu Mar 31 15:49:46 UTC 2022
waiting for 15 minutes to finish the vCenter config...
-----------------------------------------------------
Build of NSX Nested Networks - This should take less than a minute
Starting timestamp: Thu Mar 31 16:04:46 UTC 2022
Ending timestamp: Thu Mar 31 16:04:55 UTC 2022
-----------------------------------------------------
Build of the nested NSXT Manager - This should take less than 20 minutes
Starting timestamp: Thu Mar 31 16:04:55 UTC 2022
Ending timestamp: Thu Mar 31 16:22:30 UTC 2022
waiting for 5 minutes to finish the NSXT bootstrap...
-----------------------------------------------------
Build of the config of NSX-T - This should take less than 60 minutes
Starting timestamp: Thu Mar 31 16:27:30 UTC 2022
Ending timestamp: Thu Mar 31 17:20:04 UTC 2022
-----------------------------------------------------
Build of Nested Avi Controllers - This should take around 15 minutes
Starting timestamp: Thu Mar 31 17:20:04 UTC 2022
Ending timestamp: Thu Mar 31 17:34:07 UTC 2022
-----------------------------------------------------
Build of Nested Avi App - This should take less than 10 minutes
Starting timestamp: Thu Mar 31 17:34:07 UTC 2022
Ending timestamp: Thu Mar 31 17:42:27 UTC 2022
-----------------------------------------------------
Build of the config of Avi - This should take less than 20 minutes
Starting timestamp: Thu Mar 31 17:42:27 UTC 2022
Ending timestamp: Thu Mar 31 17:59:59 UTC 2022
```

## destroy the infra

```shell
/bin/bash destroy.sh
```
