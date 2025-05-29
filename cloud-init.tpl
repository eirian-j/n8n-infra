#cloud-config
package_update: true
packages:
  - docker.io
runcmd:
  - [ sh, -c, "systemctl enable --now docker" ]
  - |
    cat <<EOF > /etc/vault-agent.hcl
    exit_after_auth = false
    pid_file = "/var/run/vault-agent.pid"
    auto_auth {
      method "approle" {
        mount_path = "auth/approle"
        config = {
          role_id_file_path = "/etc/vault-role-id"
          secret_id_file_path = "/etc/vault-secret-id"
        }
      }
      sink "file" {
        config = {
          path = "/root/.vault-token"
        }
      }
    }
    template {
      source      = "static_n8n_env.tpl"
      destination = "/root/n8n_env.sh"
    }
    EOF
  - [ sh, -c, "docker run -d --name vault-agent --restart=always -v /etc/vault-agent.hcl:/etc/vault-agent.hcl -v /root/.vault-token:/root/.vault-token hashicorp/vault:latest agent -config=/etc/vault-agent.hcl" ]
  - [ sh, -c, "source /root/n8n_env.sh && docker run -d --name n8n --restart=always -p 5678:5678 -v /mnt/n8n:/home/node/.n8n n8nio/n8n" ]
