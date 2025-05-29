#cloud-config
package_update: true
packages:
  - unzip
  - jq
runcmd:
  - [ sh, -c, "curl -fsSL https://releases.hashicorp.com/vault/1.14.1/vault_1.14.1_linux_arm64.zip -o /tmp/vault.zip" ]
  - [ sh, -c, "unzip /tmp/vault.zip -d /usr/local/bin" ]
  - [ sh, -c, "mkdir -p /etc/vault /var/lib/vault" ]
  - |-
    cat <<EOF > /etc/vault/vault.hcl
    storage "file" {
      path = "/var/lib/vault/data"
    }
    listener "tcp" {
      address     = "0.0.0.0:8200"
      tls_disable = 0
      tls_cert_file = "/etc/vault/tls/vault.crt"
      tls_key_file  = "/etc/vault/tls/vault.key"
    }
    ui = true
    EOF
  - [ sh, -c, "systemctl enable --now vault" ]
  - [ sh, -c, "vault operator init -key-shares=1 -key-threshold=1 > /root/vault-init.txt" ]
  - [ sh, -c, "grep 'Initial Root Token:' -A0 /root/vault-init.txt > /root/root_token.txt" ]
  - [ sh, -c, "grep 'Unseal Key 1:' -A0 /root/vault-init.txt > /root/unseal_key.txt" ]
  - [ sh, -c, "vault operator unseal $(cut -d ' ' -f3 /root/unseal_key.txt)" ]
  - [ sh, -c, "vault login $(cut -d ' ' -f4 /root/root_token.txt)" ]
  - [ sh, -c, "vault secrets enable pki" ]
  - [ sh, -c, "vault secrets tune -max-lease-ttl=87600h pki" ]
  - [ sh, -c, "vault write pki/root/generate/internal common_name=example.com ttl=87600h" ]
  # further Vault PKI & DB engine setup via CLI or Terraform
```