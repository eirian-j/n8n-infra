resource "oci_core_virtual_network" "vcn" {
  cidr_block = "10.0.0.0/16"
  display_name = "n8n-vcn"
}

resource "oci_core_internet_gateway" "igw" {
  vcn_id        = oci_core_virtual_network.vcn.id
  display_name = "n8n-igw"
}

resource "oci_core_route_table" "rt" {
  vcn_id = oci_core_virtual_network.vcn.id
  route_rules {
    cidr_block        = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_subnet" "subnet" {
  vcn_id           = oci_core_virtual_network.vcn.id
  cidr_block       = "10.0.1.0/24"
  display_name     = "n8n-subnet"
  route_table_id   = oci_core_route_table.rt.id
  dns_label        = "n8n"
}
