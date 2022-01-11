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
  cidr_blocks    = [var.oci_vcn_cidr_block]
  dns_label      = "ocivcn"
  compartment_id = var.compartment_ocid
  display_name   = "oci-vcn"
}

##################################################################################
# Create public subnet for OCI VCN
##################################################################################
resource "oci_core_subnet" "oci-vcn-subnet" {
  cidr_block        = var.oci_subnet_cidr
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
# Grab default route table data for IGW Route rules for VCN
##################################################################################
data "oci_core_vcn" "oci-default-route-table-id" {
  vcn_id = oci_core_vcn.oci-vcn.id
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
        destination = var.onprem_cidr_block
    }
 }

###################################################################################
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

  }
  display_name = "oci-vcn-drg-attachment"
  drg_route_table_id = oci_core_drg_route_table.oci-vcn-drg-route-table.id
}

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