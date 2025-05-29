resource "oci_core_instance" "n8n" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.oci_tenancy_ocid
  display_name        = "n8n-instance"
  shape               = "VM.Standard.A1.Flex"

  source_details {
    source_type = "image"
    image_id    = data.oci_core_images.ubuntu.id
  }

  metadata = {
    ssh_authorized_keys = var.oci_ssh_public_key
    user_data           = base64encode(templatefile("${path.module}/cloud-init.tpl", {
      domain = var.domain,
      vault_addr = var.vault_addr
    }))
  }

  create_vnic_details {
    subnet_id     = oci_core_subnet.subnet.id
    assign_public_ip = true
  }
}

data "oci_core_images" "ubuntu" {
  compartment_id = var.oci_tenancy_ocid
  operating_system = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape = "VM.Standard.A1.Flex"
}

resource "oci_blockstorage_volume" "n8n_data" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.oci_tenancy_ocid
  display_name        = "n8n-block-volume"
  size_in_gbs         = 50
}

resource "oci_core_volume_attachment" "attach_n8n_data" {
  instance_id = oci_core_instance.n8n.id
  volume_id   = oci_blockstorage_volume.n8n_data.id
  attachment_type = "paravirtualized"
}
