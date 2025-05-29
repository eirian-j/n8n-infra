resource "oci_core_virtual_network" "vcn" {
  compartment_id = var.oci_tenancy_ocid
  cidr_block     = var.vcn_cidr
  display_name   = "n8n-vcn"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "igw"
}

resource "oci_core_nat_gateway" "nat" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "nat"
}

resource "oci_core_route_table" "public_rt" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "public-rt"
  route_rules {
    destination        = "0.0.0.0/0"
    network_entity_id  = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_route_table" "private_rt" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "private-rt"
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.nat.id
  }
}

# Subnets
resource "oci_core_subnet" "public" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  cidr_block     = var.public_subnet_cidr
  display_name   = "public-subnet"
  route_table_id = oci_core_route_table.public_rt.id
  dns_label      = "public"
}

resource "oci_core_subnet" "app" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  cidr_block     = var.app_subnet_cidr
  display_name   = "app-subnet"
  route_table_id = oci_core_route_table.private_rt.id
  dns_label      = "app"
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "vault" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  cidr_block     = var.vault_subnet_cidr
  display_name   = "vault-subnet"
  route_table_id = oci_core_route_table.private_rt.id
  dns_label      = "vault"
  prohibit_public_ip_on_vnic = true
}

# Network Security Groups (NSGs)
resource "oci_core_network_security_group" "lb_nsg" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "lb-nsg"
}
resource "oci_core_network_security_group" "app_nsg" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "app-nsg"
}
resource "oci_core_network_security_group" "vault_nsg" {
  compartment_id = var.oci_tenancy_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "vault-nsg"
}

# LB NSG: allow 80/443 from internet
resource "oci_core_network_security_group_security_rules" "lb_ingress" {
  nsg_id = oci_core_network_security_group.lb_nsg.id
  ingress_security_rules = [
    { protocol = "6", source = "0.0.0.0/0", tcp_options = { min = 80,  max = 80  } },
    { protocol = "6", source = "0.0.0.0/0", tcp_options = { min = 443, max = 443 } },
  ]
}
# App NSG: allow only LB and SSH from admin
resource "oci_core_network_security_group_security_rules" "app_ingress" {
  nsg_id = oci_core_network_security_group.app_nsg.id
  ingress_security_rules = [
    { protocol = "6", source = oci_core_network_security_group.lb_nsg.oci_core_network_security_group.id, tcp_options = { min = 5678, max = 5678 } },
    { protocol = "6", source = var.ssh_admin_cidr, tcp_options = { min = 22,   max = 22   } },
  ]
}
# Vault NSG: allow only App and SSH from admin
resource "oci_core_network_security_group_security_rules" "vault_ingress" {
  nsg_id = oci_core_network_security_group.vault_nsg.id
  ingress_security_rules = [
    { protocol = "6", source = oci_core_network_security_group.app_nsg.oci_core_network_security_group.id, tcp_options = { min = 8200, max = 8200 } },
    { protocol = "6", source = var.ssh_admin_cidr, tcp_options = { min = 22,    max = 22   } },
  ]
}

# Associate NSGs on each subnet's VNIC when creating instances