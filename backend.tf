terraform {
  required_version = ">= 1.5"
  backend "remote" {
    organization = "AutomAItion"
    workspaces { name = "n8n-vault" }
  }
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.oci_tenancy_ocid
}

data "oci_core_images" "ubuntu" {
  compartment_id            = var.oci_compartment_ocid
  operating_system          = "Canonical Ubuntu"
  operating_system_version  = "22.04"
  shape                     = "VM.Standard.A1.Flex"
}
