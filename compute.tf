##################################################################################
# Create compute Instance for OCI VCN
##################################################################################
resource "oci_core_instance" "oci-vcn-instance" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "oci-vcn-instance"
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id      = oci_core_subnet.oci-vcn-subnet.id
    display_name              = "Primaryvnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "oci-vcn-subnet-vnic"
  }
  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid[var.region]
  }
  metadata = {
    ssh_authorized_keys = file(var.public_key_path)
  }
}

// Gets a list of VNIC attachments on the instance
data "oci_core_vnic_attachments" "oci-vcn-instance-vnics" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domain.ad.name
  instance_id         = oci_core_instance.oci-vcn-instance.id
}

// Gets the OCID of the first (default) VNIC
data "oci_core_vnic" "oci-vcn-instance-vnic" {
  vnic_id = data.oci_core_vnic_attachments.oci-vcn-instance-vnics.vnic_attachments[0]["vnic_id"]
}

// Create Private IP for OCI VCN
resource "oci_core_private_ip" "oci-vcn-private-ip" {
  vnic_id        = data.oci_core_vnic_attachments.oci-vcn-instance-vnics.vnic_attachments[0]["vnic_id"]
  display_name   = "oci-vcn-private-ip"
  hostname_label = "oci-vcn-private-ip"
}

// List Private IPs
data "oci_core_private_ips" "oci-vcn-private-ip-datasource" {
  depends_on = [oci_core_private_ip.oci-vcn-private-ip]
  vnic_id    = oci_core_private_ip.oci-vcn-private-ip.vnic_id
}

##################################################################################
# Create compute instance for onprem VCN
##################################################################################
resource "oci_core_instance" "onprem-vcn-instance" {
  depends_on = [oci_core_private_ip.oci-vcn-private-ip]
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

// Create Private IP for onprem VCN
resource "oci_core_private_ip" "onprem-vcn-private-ip" {
  vnic_id        = data.oci_core_vnic_attachments.onprem-vcn-instance-vnics.vnic_attachments[0]["vnic_id"]
  display_name   = "onprem-vcn-private-ip"
  hostname_label = "onprem-vcn-private-ip"
}

// List Private IPs
data "oci_core_private_ips" "onprem-vcn-private-ip-datasource" {
  depends_on = [oci_core_private_ip.onprem-vcn-private-ip]
  vnic_id    = oci_core_private_ip.onprem-vcn-private-ip.vnic_id
}

##################################################################################
# Create compute instance for Libreswan in onprem VCN
##################################################################################
resource "oci_core_instance" "onprem-vcn-libreswan-instance" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "onprem-vcn-libreswan-instance"
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id      = oci_core_subnet.onprem-vcn-subnet.id
    display_name              = "Primaryvnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "onprem-libreswan-vcn-subnet-vnic"
    skip_source_dest_check = true
  }

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid[var.region]
  }
  metadata = {
    ssh_authorized_keys = file(var.public_key_path)
  }
}

// Gets a list of VNIC attachments on the instance
data "oci_core_vnic_attachments" "onprem-vcn-libreswan-instance-vnics" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domain.ad.name
  instance_id         = oci_core_instance.onprem-vcn-instance.id
}

// Gets the OCID of the first (default) VNIC
data "oci_core_vnic" "onprem-vcn-libreswan-instance-vnic" {
  vnic_id = data.oci_core_vnic_attachments.onprem-vcn-libreswan-instance-vnics.vnic_attachments[0]["vnic_id"]
}
##################################################################################
# Create tf-ansible-extra-vars
##################################################################################  
resource "null_resource" "tf-ansible-extra-vars" {
  depends_on = [local_file.tf-ansible-extra-vars]

  // Ansible integration
  provisioner "remote-exec" {
    inline = ["echo About to run Ansible on LIBRESWAN!"]

    connection {
      host        = "${oci_core_instance.onprem-vcn-libreswan-instance.public_ip}"
      type        = "ssh"
      user        = "${var.user}"
      private_key = file("${var.private_key_path}")
    }
  }

  provisioner "local-exec" {
    command = "sleep 30; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.user} -i '${oci_core_instance.onprem-vcn-libreswan-instance.public_ip},' --private-key ${var.private_key_path} libreswan-vpn.yml"
  }
}

// Create Private IP for onprem VCN
resource "oci_core_private_ip" "onprem-vcn-libreswan-private-ip" {
  vnic_id        = data.oci_core_vnic_attachments.onprem-vcn-libreswan-instance-vnics.vnic_attachments[0]["vnic_id"]
  display_name   = "onprem-vcn-libreswan-private-ip"
  hostname_label = "onprem-vcn-libreswan-private-ip"
}

// List Private IPs
data "oci_core_private_ips" "onprem-vcn-libreswan-private-ip-datasource" {
  depends_on = [oci_core_private_ip.onprem-vcn-libreswan-private-ip]
  vnic_id    = oci_core_private_ip.onprem-vcn-libreswan-private-ip.vnic_id
}