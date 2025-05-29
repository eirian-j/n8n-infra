variable "oci_tenancy_ocid" {}
variable "oci_user_ocid" {}
variable "oci_fingerprint" {}
variable "oci_private_key_path" {}
variable "oci_region" {
  default = "ap-singapore-1"
}
variable "vault_addr" {}
variable "vault_token" {
  sensitive = true
}
variable "domain" {
  description = "The DNS name for n8n (e.g. app.example.com)"
}
variable "oci_ssh_public_key" {
  description = "Public key for SSH access to the compute instance"
}