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

data "vsphere_network" "esxi_network" {
  count = 1
  name = var.vcenter_underlay.network.name
  datacenter_id = data.vsphere_datacenter.dc.id
}




//resource "vsphere_folder" "esxi_folder" {
//  path          = var.vcenter_underlay.folder
//  type          = "vm"
//  datacenter_id = data.vsphere_datacenter.dc.id
//}

resource "vsphere_content_library" "library" {
  count = (var.dns_ntp.create == true ? 1 : 0)
  name            = var.vcenter_underlay.cl.name
  storage_backing = [data.vsphere_datastore.datastore.id]
}

resource "vsphere_content_library_item" "files" {
  count = (var.dns_ntp.create == true ? 1 : 0)
  name        = basename(var.vcenter_underlay.cl.file)
  library_id  = vsphere_content_library.library[0].id
  file_url = var.vcenter_underlay.cl.file
}