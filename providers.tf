provider "oci" {
  tenancy_ocid     = var.oci_tenancy_ocid
  user_ocid        = var.oci_user_ocid
  fingerprint      = var.oci_fingerprint
  private_key_path = var.oci_private_key_path
  region           = var.oci_region
}

provider "vault" {
  address = "https://${oci_core_instance.vault.public_ip}:8200"
  token   = data.vault_generic_secret.root_token.data["token"]
}

