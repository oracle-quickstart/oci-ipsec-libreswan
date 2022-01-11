##################################################################################
# Create compute instance for onprem VCN
##################################################################################
resource "oci_core_instance" "onprem-vcn-instance" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "onprem-vcn-instance"
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id      = oci_core_subnet.onprem-vcn-subnet.id
    display_name              = "Primaryvnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "onprem-vcn-subnet-vnic"
  }

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid[var.region]
  }
  metadata = {
    ssh_authorized_keys = file(var.public_key_path)
    }
}

# Gets a list of VNIC attachments on the instance
data "oci_core_vnic_attachments" "onprem-vcn-instance-vnics" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domain.ad.name
  instance_id         = oci_core_instance.onprem-vcn-instance.id
}

# Gets the OCID of the first (default) VNIC
data "oci_core_vnic" "onprem-vcn-instance-vnic" {
  vnic_id = data.oci_core_vnic_attachments.onprem-vcn-instance-vnics.vnic_attachments[0]["vnic_id"]
}

// List Private IPs
data "oci_core_private_ips" "onprem-vcn-private-ip-datasource" {
  vnic_id    = data.oci_core_vnic.onprem-vcn-instance-vnic.id
}