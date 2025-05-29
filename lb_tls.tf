### Vault PKI backend & role ###
resource "vault_mount" "pki" {
  path = "pki"
  type = "pki"
}

resource "vault_pki_secret_backend_cert_roles" "n8n_role" {
  backend            = vault_mount.pki.path
  name               = "n8n-role"
  allowed_domains    = [ var.domain ]
  allow_subdomains   = false
  max_ttl            = "72h"
}

resource "vault_pki_secret_backend_cert" "n8n_cert" {
  backend     = vault_mount.pki.path
  name        = "n8n-role"
  common_name = var.domain
  ttl         = "72h"
}

### OCI Load Balancer ###
resource "oci_load_balancer_load_balancer" "lb" {
  compartment_id = var.oci_tenancy_ocid
  display_name   = "n8n-lb"
  shape_name     = "flexible"
  subnet_ids     = [ oci_core_subnet.subnet.id ]
}

resource "oci_load_balancer_certificate" "cert" {
  load_balancer_id = oci_load_balancer_load_balancer.lb.id
  certificate_name = "n8n-tls"
  private_key      = vault_pki_secret_backend_cert.n8n_cert.private_key
  public_certificate = vault_pki_secret_backend_cert.n8n_cert.certificate
}

resource "oci_load_balancer_listener" "https" {
  load_balancer_id = oci_load_balancer_load_balancer.lb.id
  name             = "https"
  default_backend_set_name = "n8n-backend"
  protocol         = "HTTP"
  port             = 443
  ssl_configuration {
    certificate_name = oci_load_balancer_certificate.cert.certificate_name
  }
}

resource "oci_load_balancer_backend_set" "backend" {
  load_balancer_id = oci_load_balancer_load_balancer.lb.id
  name             = "n8n-backend"
  policy           = "ROUND_ROBIN"
  health_checker {
    protocol = "HTTP"
    url_path = "/healthz"
  }
  backend {
    ip_address = oci_core_instance.n8n.public_ip
    port       = 5678
    weight     = 1
  }
}
