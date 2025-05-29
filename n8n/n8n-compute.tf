// n8n_compute.tf

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.oci_compartment_ocid
}

data "oci_core_images" "ubuntu" {
  compartment_id            = var.oci_compartment_ocid
  operating_system          = "Canonical Ubuntu"
  operating_system_version  = "22.04"
  shape                     = "VM.Standard.A1.Flex"
}

resource "oci_core_instance" "n8n" {
  compartment_id       = var.oci_compartment_ocid
  availability_domain  = data.oci_identity_availability_domains.ads.availability_domains[0].name
  shape                = "VM.Standard.A1.Flex"
  display_name         = "n8n-app"
  
  # place in the “app” subnet (private, only LB → app)
  create_vnic_details {
    subnet_id        = oci_core_subnet.app_subnet.id
    assign_public_ip = false
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    # cloud-init pulls in the Vault address, role/secret IDs, domain, MySQL host
    user_data = base64encode(
      templatefile("${path.module}/cloud-init-n8n.tpl", {
        vault_addr      = oci_core_instance.vault.private_ip,
        vault_role_id   = var.vault_role_id,
        vault_secret_id = var.vault_secret_id,
        domain          = var.domain,
        mysql_host      = oci_mysql_db_system.n8n_db.private_ip
      })
    )
  }

  shape_config {
    ocpus         = 1
    memory_in_gbs = 4
  }
}

resource "oci_blockstorage_volume" "n8n_data" {
  compartment_id      = var.oci_compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "n8n-data"
  size_in_gbs         = 50
}

resource "oci_core_volume_attachment" "n8n_attach_data" {
  instance_id       = oci_core_instance.n8n.id
  volume_id         = oci_blockstorage_volume.n8n_data.id
  attachment_type   = "paravirtualized"
}
