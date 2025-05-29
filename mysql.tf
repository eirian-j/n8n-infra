resource "oci_mysql_db_system" "n8n_db" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.oci_tenancy_ocid
  shape_name          = "MySQLHeatWaveShape"          # Free-Tier shape
  mysql_version       = "8.0.28"
  display_name        = "n8n-mysql"
  subnet_id           = oci_core_subnet.subnet.id

  mysql_config {
    name  = "default"
    value = "some-value"
  }

  # free-tier always free flag:
  is_free_tier = true
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.oci_tenancy_ocid
}
