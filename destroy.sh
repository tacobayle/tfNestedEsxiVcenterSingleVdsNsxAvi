#!/bin/bash
#
# Script to destroy the infrastructure
#
if [ -f "variables.json" ]; then
  jsonFile="variables.json"
else
  exit 1
fi
#
#
#
echo "--------------------------------------------------------------------------------------------------------------------"
#
# destroying ip route to reach overlay segments
#
for route in $(jq -c -r .external_gw.routes[] $jsonFile)
do
  sudo ip route del $(echo $route | jq -c -r '.to') via $(jq -c -r .vcenter.dvs.portgroup.management.external_gw_ip $jsonFile)
done
echo "--------------------------------------------------------------------------------------------------------------------"
#
# Destroy DNS/NTP server on the underlay infrastructure
#
echo "Destroy DNS/NTP server on the underlay infrastructure"
if [[ $(jq -c -r .dns_ntp.create $jsonFile) == true ]] ; then
  cd dns_ntp
  terraform destroy -auto-approve -var-file=../$jsonFile
  cd ..
fi
echo "--------------------------------------------------------------------------------------------------------------------"
#
# Destroy External GW server on the underlay infrastructure
#
echo "Destroy DNS/NTP server on the underlay infrastructure"
if [[ $(jq -c -r .external_gw.create $jsonFile) == true ]] ; then
  cd external_gw
  terraform destroy -auto-approve -var-file=../$jsonFile
  cd ..
fi
echo "--------------------------------------------------------------------------------------------------------------------"
#
# Destroy the nested ESXi/vCenter infrastructure
#
echo "Destroy the nested ESXi/vCenter infrastructure"
cd nested_esxi_vcenter
terraform refresh -var-file=../$jsonFile ; terraform destroy -auto-approve -var-file=../$jsonFile
cd ..
echo "--------------------------------------------------------------------------------------------------------------------"
#
# Destroy of a folder on the underlay infrastructure
#
echo "--------------------------------------------------------------------------------------------------------------------"
echo "Destroy of a folder on the underlay infrastructure"
cd vsphere_underlay_folder
terraform init
terraform destroy -auto-approve -var-file=../$jsonFile
cd ..
echo "--------------------------------------------------------------------------------------------------------------------"
#
# Delete terraform.tfstate files
#
echo "Delete terraform.tfstate files"
cd nsx/networks
rm -f terraform.tfstate
cd ../..
cd nsx/config
rm -f terraform.tfstate
cd ../..
cd avi/config
rm -f terraform.tfstate
cd ../..