#!/bin/bash
#
if [ -f "../variables.json" ]; then
  jsonFile="../variables.json"
else
  exit 1
fi
#
api_host="$(jq -r .vcenter.name $jsonFile).$(jq -r .dns.domain $jsonFile)"
vcenter_username=administrator
vcenter_domain=$(jq -r .vcenter.sso.domain_name $jsonFile)
vcenter_password=$TF_VAR_vcenter_password
#
load_govc_env () {
  export GOVC_USERNAME="$vcenter_username@$vcenter_domain"
  export GOVC_PASSWORD=$vcenter_password
  export GOVC_DATACENTER=$(jq -r .vcenter.datacenter $jsonFile)
  export GOVC_INSECURE=true
  export GOVC_CLUSTER=$(jq -r .vcenter.cluster $jsonFile)
  export GOVC_URL=$api_host
}
#
load_govc_esxi () {
  export GOVC_USERNAME="root"
  export GOVC_PASSWORD=$TF_VAR_esxi_root_password
  export GOVC_INSECURE=true
  unset GOVC_DATACENTER
  unset GOVC_CLUSTER
  unset GOVC_URL
}
#
curl_put () {
#  echo $1
#  echo $2
#  echo https://$3/api/$4
  status_code=$(curl -k -X PUT -H "vmware-api-session-id: $1" -H "Content-Type: application/json" -d $2 -w "%{http_code}" --silent -o /dev/null "https://$3/api/$4")
  re='^20[0-9]+$'
  if [[ "$status_code"  =~ $re ]] ; then
    echo "Config for $(basename $4) has been done successfully"
  else
    echo "!!! ERROR !!! : Config for $(basename $4) failed with HTTP code $status_code"
    exit 1
  fi
}
#
curl_post () {
  echo $1
  echo $2
  echo https://$3/api/$4
  status_code=$(curl -k -X POST -H "vmware-api-session-id: $1" -H "Content-Type: application/json" -d $2 -w "%{http_code}" --silent -o /dev/null "https://$3/api/$4")
  echo $status_code
  re='^20[0-9]+$'
  if [[ "$status_code"  =~ $re ]] ; then
    echo "Adding new $(basename $4) has been done successfully"
  else
    echo "!!! ERROR !!! : Adding new $(basename $4) failed with HTTP code $status_code"
    exit 1
  fi
}
#
token=$(curl -k -s -X POST -u "$vcenter_username@$vcenter_domain:$vcenter_password" https://$api_host/api/session -H "Content-Type: application/json" | tr -d \")
#echo $token
#echo https://$api_host/api/appliance/access/ssh
#curl -k -X PUT -H "vmware-api-session-id: $token" -H "Content-Type: application/json" -d '{"enabled":true}' https://$api_host/api/appliance/access/ssh
#curl -k -X PUT -H "vmware-api-session-id: $token" -H "Content-Type: application/json" -d '{"enabled":true}' https://$api_host/api/appliance/access/dcui
#curl -k -X PUT -H "vmware-api-session-id: $token" -H "Content-Type: application/json" -d '{"enabled":true}' https://$api_host/api/appliance/access/consolecli
#curl -k -X PUT -H "vmware-api-session-id: $token" -H "Content-Type: application/json" -d '{"enabled":true,"timeout":120}' https://$api_host/api/appliance/access/shell
curl_put $token '{"enabled":true}' $api_host "appliance/access/ssh"
curl_put $token '{"enabled":true}' $api_host "appliance/access/dcui"
curl_put $token '{"enabled":true}' $api_host "appliance/access/consolecli"
curl_put $token '{"enabled":true,"timeout":120}' $api_host "appliance/access/shell"
curl_put $token '{"max_days":0,"min_days":0,"warn_days":0}' $api_host "appliance/local-accounts/global-policy"
#curl -k -H "vmware-api-session-id: $token" -H "Content-Type: application/json" https://$api_host/api/appliance/ntp
curl_put $token '{"name":'\"$(jq -r .ntp.timezone $jsonFile)\"'}' $api_host "appliance/system/time/timezone"
#curl -k -H "vmware-api-session-id: $token" https://$api_host/api/vcenter/host
#echo $(curl -k -H "vmware-api-session-id: $token" --silent https://$api_host/api/vcenter/folder)
#IFS=$'\n'
##curl -k -H "vmware-api-session-id: $token" --silent https://$api_host/api/vcenter/folder | jq -c -r .[]
#for folder in $(curl -k -H "vmware-api-session-id: $token" --silent https://$api_host/api/vcenter/folder | jq -c -r .[])
#do
##  echo $folder
#  if [[ $(echo $folder | jq -c -r .type) == "HOST" ]] ; then
##    echo $folder
#    folder_host=$(echo $folder | jq -c -r .folder)
##    echo $folder_host
##    echo "toto"
#  fi
#done
#
# Add host in the cluster
#
IFS=$'\n'
count=1
for ip in $(jq -r .vcenter.dvs.portgroup.management.esxi_ips[] $jsonFile)
do
  load_govc_env
  if [[ $count -ne 1 ]] ; then
  echo "Adding host $ip in the cluster"
  govc cluster.add -hostname "$(jq -r .esxi.basename $jsonFile)$count.$(jq -r .dns.domain $jsonFile)" -username "root" -password "$TF_VAR_esxi_root_password" -noverify
#   govc cluster.add -hostname $ip -username "root" -password "$TF_VAR_esxi_root_password" -noverify
#   $(jq -r .esxi.basename $jsonFile)-0$(count)".$(jq -r .dns.domain $jsonFile)
#  govc host.maintenance.exit $ip
#  curl_post $token '{"folder":'\"$folder_host\"',"hostname":'\"$ip\"',"password":'\"$TF_VAR_esxi_root_password\"',"thumbprint_verification":"NONE","user_name":"root"}' $api_host "vcenter/host"
  fi
  count=$((count+1))
done
#
#curl -k -H "vmware-api-session-id: $token" https://$api_host/api/vcenter/host
#  curl_post $token '{"folder":'\"$folder_host\"',"hostname":'\"$ip\"',"password":'\"$TF_VAR_esxi_root_password\"',"thumbprint_verification":"NONE","user_name":"root"}' $api_host "vcenter/host"
#
# Network config
#
#
# if single vds switch
load_govc_env
govc dvs.create -mtu $(jq -r .vcenter.dvs.mtu $jsonFile) -discovery-protocol $(jq -r .vcenter.dvs.discovery_protocol $jsonFile) -product-version=$(jq -r .vcenter.dvs.version $jsonFile) "$(jq -r .vcenter.dvs.basename $jsonFile)-0"
govc dvs.portgroup.add -dvs "$(jq -r .vcenter.dvs.basename $jsonFile)-0" -vlan $(jq -r .vcenter.dvs.portgroup.management.vlan $jsonFile) "$(jq -r .vcenter.dvs.portgroup.management.name $jsonFile)"
govc dvs.portgroup.add -dvs "$(jq -r .vcenter.dvs.basename $jsonFile)-0" -vlan $(jq -r .vcenter.dvs.portgroup.management.vlan $jsonFile) "$(jq -r .vcenter.dvs.portgroup.management.name $jsonFile)-vmk"
govc dvs.portgroup.add -dvs "$(jq -r .vcenter.dvs.basename $jsonFile)-0" -vlan $(jq -r .vcenter.dvs.portgroup.VMotion.vlan $jsonFile) "$(jq -r .vcenter.dvs.portgroup.VMotion.name $jsonFile)"
govc dvs.portgroup.add -dvs "$(jq -r .vcenter.dvs.basename $jsonFile)-0" -vlan $(jq -r .vcenter.dvs.portgroup.VSAN.vlan $jsonFile) "$(jq -r .vcenter.dvs.portgroup.VSAN.name $jsonFile)"
IFS=$'\n'
count=1
for ip in $(jq -r .vcenter.dvs.portgroup.management.esxi_ips[] $jsonFile)
do
  govc dvs.add -dvs "$(jq -r .vcenter.dvs.basename $jsonFile)-0" -pnic=vmnic0 "$(jq -r .esxi.basename $jsonFile)$count.$(jq -r .dns.domain $jsonFile)"
  count=$((count+1))
done
#
sleep 5
#
#echo "++++++++++++++++++++++++++++++++"
#echo "Migrating vmk0, vmk1, vmk2 to from standard switch to VDS switch"
#ansible-playbook pb-migrate-vmk.yml --extra-vars "@variables.json"
#
#
#
echo "++++++++++++++++++++++++++++++++"
echo "Update vCenter Appliance port group location"
load_govc_env
govc vm.network.change -vm $(jq -r .vcenter.name $jsonFile) -net $(jq -r .vcenter.dvs.portgroup.management.name $jsonFile) ethernet-0 &
govc_pid=$(echo $!)
echo "Waiting 5 secs to check if vCenter VM is UP"
sleep 10
if ping -c 1 $api_host &> /dev/null
then
  echo "vCenter VM is UP"
  #
  # Sometimes the GOVC command to migrate the vCenter VM to new port group fails
  #
  kill $(echo $govc_pid) || true
else
  echo "vCenter VM is DOWN - exit script config"
  exit
fi
