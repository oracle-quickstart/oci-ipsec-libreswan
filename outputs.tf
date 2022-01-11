##################################################################################
# Output for OCI cloud VCN
##################################################################################
output "oci-vcn-id" {
  value = oci_core_vcn.oci-vcn.id
}
##################################################################################
# Output for simualted on-prem data center using isolated OCI cloud VCN
##################################################################################
output "onprem-vcn-id" {
  value = oci_core_vcn.onprem-vcn.id
}
##################################################################################
# Output for oci-vcn-drg
##################################################################################
output "oci-vcn-drg-id" {
  value = oci_core_drg.oci-vcn-drg.id
}
##################################################################################
# Output for compute public IPs for OCI VCN
##################################################################################
output "oci-vcn-instance-public-ip" {
  value = oci_core_instance.oci-vcn-instance.public_ip
}
##################################################################################
# Output for compute public IPs for onprem VCN
##################################################################################
output "onprem-vcn-instance-public-ip" {
  value = oci_core_instance.onprem-vcn-instance.public_ip
}
##################################################################################
# Output for compute private IPs for OCI VCN
##################################################################################
output "oci-vcn-instance-private-ip" {
  value = oci_core_instance.oci-vcn-instance.private_ip
}
##################################################################################
# Output for compute private IPs for onprem VCN
##################################################################################
output "onprem-vcn-instance-private-ip" {
  value = oci_core_instance.onprem-vcn-instance.private_ip
}
##################################################################################
# Output for compute public IPs for onprem libreswan VCN
##################################################################################
output "onprem-vcn-libreswan-instance-public-ip" {
  value = oci_core_instance.onprem-vcn-libreswan-instance.public_ip
}
##################################################################################
# Output for compute private IPs for onprem libreswan VCN
##################################################################################
output "onprem-vcn-libreswan-instance-private-ip" {
  value = oci_core_instance.onprem-vcn-libreswan-instance.private_ip
}
##################################################################################
# Output for IPSEC tunnel-a headend IP address VCN
##################################################################################
output "oci-ipsec-connection-tunnel-a" {
  value = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels[0].vpn_ip
}
##################################################################################
# Output for IPSEC tunnel-b headend IP address VCN
##################################################################################
output "oci-ipsec-connection-tunnel-b" {
  value = data.oci_core_ipsec_connection_tunnels.oci-ipsec-connection-tunnels.ip_sec_connection_tunnels[1].vpn_ip
}