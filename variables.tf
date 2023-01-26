variable "tenancy_ocid" {
    type = string
}
variable "compartment_ocid" {
    type = string
}
variable "user_ocid" {
    type = string
}
variable "fingerprint" {
    type = string
}
# Terraform 
variable "pem_private_key_path" {
    type = string
}
variable "private_key_path" {
    type = string
}
variable "public_key_path" {
    type = string
}
variable "region" {
    type = string
    default = "us-ashburn-1"
}
variable "default_oci_vcn_route_table" {
    type = string
}
variable "user" {
    type = string
}
variable "oci_subnet_cidr" {
    type = string
    default = "192.168.100.0/25"
}
variable "onprem_subnet_cidr" {
    type = string
    default = "172.16.100.0/25"
}
variable "oci_vcn_cidr_block" {
    type = string
    default = "192.168.100.0/24"
}
variable "onprem_cidr_block" {
    type = string
    default = "172.16.100.0/24"
}
variable "bgp_cust_tunnela_ip" {
    type = string
    default = "10.10.100.101/30"
}
variable "bgp_oci_tunnela_ip" {
    type = string
    default = "10.10.100.102/30"
}
variable "bgp_cust_tunnelb_ip" {
    type = string
    default = "10.10.200.201/30"
}
variable "bgp_oci_tunnelb_ip" {
    type = string
    default = "10.10.200.202/30"
}
variable "shared_secret_psk" {
    type = string
}
variable "instance_image_ocid" {
  type = map(string)

  default = {
    # See https://docs.us-phoenix-1.oraclecloud.com/images/
    # Oracle-provided image "Oracle-Linux-7.5-2018.10.16-0"
    us-phoenix-1   = "ocid1.image.oc1.phx.aaaaaaaaoqj42sokaoh42l76wsyhn3k2beuntrh5maj3gmgmzeyr55zzrwwa"
    us-ashburn-1   = "ocid1.image.oc1.iad.aaaaaaaageeenzyuxgia726xur4ztaoxbxyjlxogdhreu3ngfj2gji3bayda"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaitzn6tdyjer7jl34h2ujz74jwy5nkbukbh55ekp6oyzwrtfa4zma"
    uk-london-1    = "ocid1.image.oc1.uk-london-1.aaaaaaaa32voyikkkzfxyo4xbdmadc2dmvorfxxgdhpnk6dw64fa3l4jh7wa"
  }
}
variable "instance_shape" {
  default = "VM.Standard2.1"
}