data "oci_identity_availability_domains" "ads" {
  compartment_id = var.oci_tenancy_ocid
}

resource "oci_core_instance" "vault" {
  compartment_id      = var.oci_tenancy_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  shape               = "VM.Standard.A1.Flex"
  shape_config {
    ocpus         = var.vault_ocpus
    memory_in_gbs = var.vault_memory
  }
  display_name = "vault-server"

  create_vnic_details {
    subnet_id            = oci_core_subnet.vault.id
    assign_public_ip     = false
    network_security_group_ids = [ oci_core_network_security_group.vault_nsg.id ]
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(templatefile("${path.module}/cloud-init-vault.tpl", {}))
  }
}

resource "oci_blockstorage_volume" "vault_data" {
  compartment_id     = var.oci_tenancy_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name       = "vault-data"
  size_in_gbs        = 50
}
resource "oci_core_volume_attachment" "vault_attach" {
  instance_id     = oci_core_instance.vault.id
  volume_id       = oci_blockstorage_volume.vault_data.id
  attachment_type = "paravirtualized"
}