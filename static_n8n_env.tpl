#!/bin/bash
export N8N_HOST="{{ .domain }}"
export N8N_PORT=5678
export N8N_PROTOCOL=https

# MySQL creds from Vault DB secrets engine
export DB_TYPE=mysql
export DB_MYSQLDB={{ with secret "database/creds/n8n-role" }}{{ .Data.username }}{{ end }}
export DB_MYSQLPASSWORD={{ with secret "database/creds/n8n-role" }}{{ .Data.password }}{{ end }}
export DB_MYSQL_HOST={{ .mysql_host }}     # optionally templated via Terraform
export DB_MYSQL_PORT=3306
export DB_MYSQL_DATABASE={{ .mysql_database }}

# n8n encryption key
export N8N_ENCRYPTION_KEY={{ with secret "secret/data/n8n" }}{{ .Data.data.encryption_key }}{{ end }}
