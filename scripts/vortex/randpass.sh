#!/bin/bash

generate_random_password() {
  local length=${1:-16} # By defatul 16 characters long
  local num_bytes=$(echo "scale=0; ($length * 3 / 4) + 1" | bc)
  
  head -c "$num_bytes" /dev/urandom | base64 | head -c "$length"
}

MYSQL=$(generate_random_password 16)
REDIS=$(generate_random_password 16)
RABBITMQ=$(generate_random_password 16)

cat <<EOF > ./default-env/global-core.json
{
  "MYSQL": "${MYSQL}",
  "REDIS": "${REDIS}",
  "RABBITMQ": "${RABBITMQ}"
}
EOF

