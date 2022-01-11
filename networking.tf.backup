##################################################################################
# Grab AD data for OCI VCN
##################################################################################
data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

##################################################################################
#  Create OCI cloud VCN
##################################################################################
resource "oci_core_vcn" "oci-vcn" {
  cidr_blocks    = ["10.16.0.0/16"]
  dns_label      = "ocivcn"
  compartment_id = var.compartment_ocid
  display_name   = "oci-vcn"
}

##################################################################################
# Create simualted on-prem data center using isolated OCI cloud VCN
##################################################################################
resource "oci_core_vcn" "onprem-vcn" {
  cidr_blocks    = ["172.16.0.0/16"]
  dns_label      = "onpremvcn"
  compartment_id = var.compartment_ocid
  display_name   = "onprem-vcn"
}

##################################################################################
# Create public subnet for OCI VCN
##################################################################################
resource "oci_core_subnet" "oci-vcn-subnet" {
  cidr_block        = var.oci_cidr
  display_name      = "oci-vcn-subnet"
  dns_label         = "ocivcnsubnet"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.oci-vcn.id
  security_list_ids = [oci_core_vcn.oci-vcn.default_security_list_id]
  route_table_id    = oci_core_vcn.oci-vcn.default_route_table_id
  dhcp_options_id   = oci_core_vcn.oci-vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = false
}
##################################################################################
# Create public subnet for onprem VCN
##################################################################################
resource "oci_core_subnet" "onprem-vcn-subnet" {
  cidr_block        = var.onprem_cidr
  display_name      = "onprem-vcn-subnet"
  dns_label         = "onpremvcnsubnet"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.onprem-vcn.id
  security_list_ids = [oci_core_vcn.onprem-vcn.default_security_list_id]
  route_table_id    = oci_core_vcn.onprem-vcn.default_route_table_id
  dhcp_options_id   = oci_core_vcn.onprem-vcn.default_dhcp_options_id
}

##################################################################################
# Add rule to security list for public subnet for OCI VCN
##################################################################################
resource "oci_core_default_security_list" "oci-vcn-subnet-security-list" {
  compartment_id    = var.compartment_ocid
  manage_default_resource_id = oci_core_vcn.oci-vcn.default_security_list_id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "all"
    source = "0.0.0.0/0"
  }
}

##################################################################################
# Add rule to security list for public subnet for onprem VCN
##################################################################################
resource "oci_core_default_security_list" "onprem-vcn-subnet-security-list" {
  compartment_id    = var.compartment_ocid
  manage_default_resource_id = oci_core_vcn.onprem-vcn.default_security_list_id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "all"
    source = "0.0.0.0/0"
  }
}

##################################################################################
# Grab default route table data for IGW Route rules for both VCN
##################################################################################
data "oci_core_vcn" "oci-default-route-table-id" {
  vcn_id = oci_core_vcn.oci-vcn.id
}

data "oci_core_vcn" "onprem-default-route-table-id" {
  vcn_id = oci_core_vcn.onprem-vcn.id
}

##################################################################################
# Create IGW for OCI VCN
##################################################################################
resource "oci_core_internet_gateway" "oci-internet-gateway" {
    #Required
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.oci-vcn.id
    #Optional
    display_name = "oci-igw"
}

// Create IGW and DRG route rules for OCI VCN default route table
resource "oci_core_default_route_table" "oci-default-route-table" {
    #Required
    compartment_id = var.compartment_ocid
    manage_default_resource_id = data.oci_core_vcn.oci-default-route-table-id.default_route_table_id

    route_rules {
        #Required
        network_entity_id = oci_core_internet_gateway.oci-internet-gateway.id
        #Optional
        destination = "0.0.0.0/0"
    }

    route_rules {
        #Required
        network_entity_id = oci_core_drg.oci-vcn-drg.id
        #Optional
        destination = var.onprem_cidr
    }
 }
##################################################################################
# Create IGW for onprem VCN
##################################################################################
resource "oci_core_internet_gateway" "onprem-internet-gateway" {
    #Required
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.onprem-vcn.id
    #Optional
    display_name = "onprem-igw"
}

// Create IGW and Private route rules for onprem VCN
resource "oci_core_default_route_table" "onprem-default-route-table" {
    #Required
    depends_on = [oci_core_instance.onprem-vcn-libreswan-instance]
    compartment_id = var.compartment_ocid
    manage_default_resource_id = data.oci_core_vcn.onprem-default-route-table-id.default_route_table_id

    route_rules {
        #Required
        network_entity_id = oci_core_internet_gateway.onprem-internet-gateway.id
        #Optional
        destination = "0.0.0.0/0"
    }
    
    route_rules {
        #Required
        network_entity_id = "${lookup(data.oci_core_private_ips.onprem-vcn-libreswan-instance-vnic-private-ip-id.private_ips[0],"id")}"
        #Optional
        destination = "10.16.1.0/24"
    }    
}

data "oci_core_private_ips" "onprem-vcn-libreswan-instance-vnic-private-ip-id" {
    #Optional
    ip_address = oci_core_instance.onprem-vcn-libreswan-instance.private_ip
    subnet_id = oci_core_subnet.onprem-vcn-subnet.id
}

##################################################################################
# Create DRG for OCI cloud VCN
##################################################################################
resource "oci_core_drg" "oci-vcn-drg" {
  // Required
  compartment_id = var.compartment_ocid
  // Optional
  display_name = "oci-vcn-drg"
}

// Create DRG Route Table for OCI cloud VCN

// NOTE - no support for maanging default DRG route table natively 
resource "oci_core_drg_route_table" "oci-vcn-drg-route-table" {
  drg_id = oci_core_drg.oci-vcn-drg.id
  display_name = "oci-vcn-drg-route-table"
  import_drg_route_distribution_id = oci_core_drg_route_distribution.oci-vcn-drg-route-distribution.id
}

//Create DRG attachment for OCI VCN
resource "oci_core_drg_attachment" "oci-vcn-drg-attachment" {
  drg_id = oci_core_drg.oci-vcn-drg.id
  network_details {
    id = oci_core_vcn.oci-vcn.id
    type = "VCN"
    # route_table_id = oci_core_route_table.oci-vcn-drg.id
  }
  display_name = "oci-vcn-drg-attachment"
  drg_route_table_id = oci_core_drg_route_table.oci-vcn-drg-route-table.id
}

# // Add DRG route rule for OCI VCN
# resource "oci_core_drg_route_table_route_rule" "oci-vcn-drg-route-table-route-rule" {
#   // Required - RT ID FOR VCN - drg 'id' + drg VCN route table 'id' + 
#   drg_route_table_id = oci_core_drg_route_table.oci-vcn-drg-route-table.id
#   destination                = var.oci_cidr
#   destination_type           = "CIDR_BLOCK"
#   next_hop_drg_attachment_id = oci_core_drg_attachment.oci-vcn-drg-attachment.id
# }

// Add DRG route distribution for OCI VCN
resource "oci_core_drg_route_distribution" "oci-vcn-drg-route-distribution" {
  // Required
  drg_id = oci_core_drg.oci-vcn-drg.id
  distribution_type = "IMPORT"
  // optional
  display_name = "oci-vcn-drg-route-distribution"
}
resource "oci_core_drg_route_distribution_statement" "oci-vcn-drg-route-distributio-statements" {
  // Required
  drg_route_distribution_id = oci_core_drg_route_distribution.oci-vcn-drg-route-distribution.id
  action = "ACCEPT"
  match_criteria {}
  priority = 1
}
######################################################################################
# Create IPSEC Connections - NOTE: There is a bug that results in an error during
# Re-run 'terraform apply' once error occurs and terraform will complete successfully
######################################################################################
data "oci_core_cpe_device_shapes" "oci-ipsec-cpe-device-shapes" {
}

data "oci_core_cpe_device_shape" "oci-ipsec-cpe-device-shape" {
  cpe_device_shape_id = data.oci_core_cpe_device_shapes.oci-ipsec-cpe-device-shapes.cpe_device_shapes[1].cpe_device_shape_id
}

// Create IPSEC CPE for OCI VCN
resource "oci_core_cpe" "oci-ipsec-cpe" {
  compartment_id      = var.compartment_ocid
  display_name        = "oci-ipsec-cpe"
  ip_address          = oci_core_instance.onprem-vcn-libreswan-instance.public_ip
  cpe_device_shape_id = data.oci_core_cpe_device_shape.oci-ipsec-cpe-device-shape.id
}
// Cretae IPSEC connection for OCI VCN
resource "oci_core_ipsec" "oci-ipsec-connection" {
  #Required
  compartment_id = var.compartment_ocid
  cpe_id         = oci_core_cpe.oci-ipsec-cpe.id
  drg_id         = oci_core_drg.oci-vcn-drg.id
  static_routes  = [var.onprem_cidr]

  #Optional
  cpe_local_identifier      = oci_core_instance.onprem-vcn-libreswan-instance.public_ip
  cpe_local_identifier_type = "IP_ADDRESS"
  display_name = "oci-ipsec-connection"
}

//Grab data for IPSEC connection for OCI VCN tunnels
data "oci_core_ipsec_connections" "oci-ipsec-connections" {
  #Required
  compartment_id = var.compartment_ocid

  #Optional
  cpe_id = oci_core_cpe.oci-ipsec-cpe.id
  drg_id = oci_core_drg.oci-vcn-drg.id
}

data "oci_core_ipsec_connection_tunnels" "oci-ipsec-connection-tunnels" {
  ipsec_id = oci_core_ipsec.oci-ipsec-connection.id
}

data "oci_core_ipsec_connection_tunnel" "oci-ipsec-connection-tunnel-a" {
  ipsec_id  = oci_core_ipsec.oci-ipsec-connection.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels[0].id
}

data "oci_core_ipsec_connection_tunnel" "oci-ipsec-connection-tunnel-b" {
  ipsec_id  = oci_core_ipsec.oci-ipsec-connection.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels[1].id
}

// Create IPSEC connection management for OCI VCN tunnel a
resource "oci_core_ipsec_connection_tunnel_management" "oci-ipsec-connection-tunnel-management-a" {
  ipsec_id  = oci_core_ipsec.oci-ipsec-connection.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels[0].id
  depends_on = [data.oci_core_ipsec_connections.oci-ipsec-connections]

  #Optional
  bgp_session_info {
    customer_bgp_asn      = "1234"
    customer_interface_ip = "192.168.100.101/30"
    oracle_interface_ip   = "192.168.100.102/30"
  }

  display_name  = "oci-ipsec-tunnel-a"
  routing       = "BGP"
  shared_secret = "${var.shared_secret_psk}"
  ike_version   = "V1"
}

// Create IPSEC connection management for OCI VCN tunnel b
resource "oci_core_ipsec_connection_tunnel_management" "oci-ipsec-connection-tunnel-management-b" {
  ipsec_id  = oci_core_ipsec.oci-ipsec-connection.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels[1].id
  depends_on = [data.oci_core_ipsec_connections.oci-ipsec-connections]

  #Optional
  bgp_session_info {
    customer_bgp_asn      = "1234"
    customer_interface_ip = "192.168.200.201/30"
    oracle_interface_ip   = "192.168.200.202/30"
  }

  display_name  = "oci-ipsec-tunnel-b"
  routing       = "BGP"
  shared_secret = "${var.shared_secret_psk}"
  ike_version   = "V1"
}
##################################################################################
# Update drg ipsec attachment with route tables for OCI VCN tunnels
##################################################################################
// OCI VCN tunnel-a
resource "oci_core_drg_attachment_management" "oci-vcn-drg-ipsec-attachment-tunnel-a" {
  attachment_type = "IPSEC_TUNNEL"
  compartment_id = var.compartment_ocid
  network_id = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels.0.id
  drg_id = oci_core_drg.oci-vcn-drg.id
  display_name = "oci-vcn-drg-ipsec-attachment-tunnel-a"
  drg_route_table_id = oci_core_drg_route_table.oci-vcn-drg-route-table.id
}

// OCI VCN tunnel-b
resource "oci_core_drg_attachment_management" "oci-vcn-drg-ipsec-attachment-tunnel-b" {
  attachment_type = "IPSEC_TUNNEL"
  compartment_id = var.compartment_ocid
  network_id = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels.1.id
  drg_id = oci_core_drg.oci-vcn-drg.id
  display_name = "oci-vcn-drg-ipsec-attachment-tunnel-b"
  drg_route_table_id = oci_core_drg_route_table.oci-vcn-drg-route-table.id
}

// Grab data for IPSEC tunnel routes for OCI VCN
data "oci_core_ipsec_connection_tunnel_routes" "oci-ipsec-connection-tunnel-a-routes" {
  #Required
  ipsec_id  = oci_core_ipsec.oci-ipsec-connection.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels.0.id
  #Optional
  advertiser = "CUSTOMER"
}

data "oci_core_ipsec_connection_tunnel_routes" "oci-ipsec-connection-tunnel-b-routes" {
  #Required
  ipsec_id  = oci_core_ipsec.oci-ipsec-connection.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels.1.id
  #Optional
  advertiser = "CUSTOMER"
}