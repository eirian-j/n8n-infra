variable "oci_tenancy_ocid" { type = string }
variable "oci_user_ocid"   { type = string }
variable "oci_fingerprint" { type = string }
variable "oci_private_key_path" { type = string }
variable "oci_region" {
  type    = string
  default = "ap-singapore-1"
}

variable "ssh_admin_cidr" {
  description = "CIDR range for SSH access (your office IP)"
  type        = string
}
variable "ssh_public_key" {
  description = "Your SSH public key"
  type        = string
}

variable "domain" {
  description = "DNS name for n8n (e.g. app.example.com)"
  type        = string
}

# Vault instance attributes
variable "vault_ocpus" {
  type    = number
  default = 1
}
variable "vault_memory" {
  type    = number
  default = 4
}

variable "vault_app_role" {
  description = "Vault AppRole path (e.g. auth/approle)"
  type        = string
  default     = "auth/approle"
}

variable "vault_addr" {
  description = "The address of the Vault server"
  type        = string
}

variable "vault_token" {
  description = "Vault root token"
  type        = string
}

# Names for subnets
variable "vcn_cidr"    { default = "10.0.0.0/16" }
variable "public_subnet_cidr"  { default = "10.0.1.0/24" }
variable "app_subnet_cidr"     { default = "10.0.2.0/24" }
variable "vault_subnet_cidr"   { default = "10.0.3.0/24" }