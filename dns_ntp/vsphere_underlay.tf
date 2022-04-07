data "vsphere_datacenter" "dc" {
  name = var.vcenter_underlay.dc
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vcenter_underlay.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name = var.vcenter_underlay.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.vcenter_underlay.resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}



//resource "vsphere_folder" "esxi_folder" {
//  path          = var.vcenter_underlay.folder
//  type          = "vm"
//  datacenter_id = data.vsphere_datacenter.dc.id
//}

//data "vsphere_folder" "esxi_folder" {
//  path = "/${var.vcenter_underlay.dc}/${var.vcenter_underlay.datastore}/${var.vcenter_underlay.folder}"
//}