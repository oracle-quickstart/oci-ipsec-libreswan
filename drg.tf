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