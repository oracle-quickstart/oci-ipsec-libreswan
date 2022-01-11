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
  static_routes  = [var.onprem_subnet_cidr]

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
    customer_interface_ip = var.bgp_cust_tunnela_ip
    oracle_interface_ip   = var.bgp_oci_tunnela_ip
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
    customer_interface_ip = var.bgp_cust_tunnelb_ip
    oracle_interface_ip   = var.bgp_oci_tunnelb_ip
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