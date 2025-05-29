# cloud-init-n8n.tpl

#cloud-config
package_update: true
packages:
  - docker.io
  - jq           # for parsing Vault JSON
runcmd:
  # 1) Enable and start Docker
  - [ sh, -c, "systemctl enable --now docker" ]

  # 2) Drop Vault Agent config
  - |
    cat <<EOF >/etc/vault-agent.hcl
    exit_after_auth = false
    pid_file       = "/var/run/vault-agent.pid"
    vault {
      address = "${vault_addr}"
    }
    auto_auth {
      method "approle" {
        mount_path = "auth/approle"
        config = {
          role_id_file_path   = "/etc/vault-role-id"
          secret_id_file_path = "/etc/vault-secret-id"
        }
      }
      sink "file" {
        config = { path = "/root/.vault-token" }
      }
    }
    template {
      source      = "/etc/vault-template.hcl"
      destination = "/root/env.sh"
      command     = "chmod +x /root/env.sh"
    }
    EOF

  # 3) Drop the template that renders all env vars
  - |
    cat <<'EOF' >/etc/vault-template.hcl
    #!/bin/bash
    # Load Vault token
    export VAULT_TOKEN=$(cat /root/.vault-token)

    #### PKI for TLS certs ####
    # Issue fullchain + key into files
    vault read -format=json pki/issue/n8n-role common_name=${domain} ttl=72h \
      | jq -r '.data.certificate'   > /root/fullchain.crt
    vault read -format=json pki/issue/n8n-role common_name=${domain} ttl=72h \
      | jq -r '.data.private_key'    > /root/privkey.key
    export TLS_CRT=/root/fullchain.crt
    export TLS_KEY=/root/privkey.key

    #### Database creds ####
    # Dynamic MySQL user rotation
    vault read -format=json database/creds/n8n-role \
      | jq -r '.data.username'       > /etc/db_user
    vault read -format=json database/creds/n8n-role \
      | jq -r '.data.password'       > /etc/db_pass
    export DB_TYPE=mysql
    export DB_MYSQL_HOST=${mysql_host}
    export DB_MYSQL_PORT=3306
    export DB_MYSQL_DATABASE=n8n
    export DB_MYSQL_USERNAME=$(cat /etc/db_user)
    export DB_MYSQL_PASSWORD=$(cat /etc/db_pass)

    #### n8n Encryption Key ####
    vault kv get -field=encryption_key secret/data/n8n > /root/enc_key
    export N8N_ENCRYPTION_KEY=$(cat /root/enc_key)

    #### n8n Host Settings ####
    export N8N_PROTOCOL=https
    export N8N_HOST=${domain}
    export N8N_PORT=5678
    EOF

  # 4) Inject AppRole creds (from TF Cloud workspace vars)
  - |
    echo "${vault_role_id}"   > /etc/vault-role-id && chmod 600 /etc/vault-role-id
  - |
    echo "${vault_secret_id}" > /etc/vault-secret-id && chmod 600 /etc/vault-secret-id

  # 5) Launch Vault Agent
  - |
    docker run -d --name vault-agent --restart=always \
      -v /etc/vault-agent.hcl:/etc/vault-agent.hcl \
      -v /etc/vault-template.hcl:/etc/vault-template.hcl \
      hashicorp/vault:1.14.0 agent -config=/etc/vault-agent.hcl

  # 6) Boot n8n once env.sh is rendered
  - |
    sleep 5
    source /root/env.sh
    docker run -d --name n8n --restart=always \
      -p 5678:5678 \
      -v /mnt/n8n:/home/node/.n8n \
      -e N8N_PROTOCOL \
      -e N8N_HOST \
      -e N8N_PORT \
      -e TLS_CRT \
      -e TLS_KEY \
      -e DB_TYPE \
      -e DB_MYSQL_HOST \
      -e DB_MYSQL_PORT \
      -e DB_MYSQL_DATABASE \
      -e DB_MYSQL_USERNAME \
      -e DB_MYSQL_PASSWORD \
      -e N8N_ENCRYPTION_KEY \
      n8nio/n8n
