#!/bin/bash

initialize() {
  docker run --rm -it -v "$(pwd)":/app -w /app docker.io/cockroachdb/cockroach:v24.2.1 bash -c "
    cd compose/services/database &&     cockroach cert create-ca --certs-dir=./ --ca-key=ca.key &&     for node in roach1 roach2 roach3; do       cockroach cert create-node \$node roach-lb --certs-dir=./ --ca-key=ca.key &&       mkdir -p node\${node: -1}/certs && mv node.* node\${node: -1}/certs;     done &&     for client in root zitadel fury strife death war; do       cockroach cert create-client \$client --certs-dir=./ --ca-key=ca.key &&       mkdir -p clients/\$client && mv client.* clients/\$client;     done &&     chown 1000:1000 -R .
  "

  git submodule foreach 'cp .env.example .env'

  docker compose -f compose/compose.yaml up -d

  sleep 10

  docker exec -it compose-roach1-1 ./cockroach --host roach1:26357 init --certs-dir /run/secrets
}

update_client_id() {
  CLIENT_ID="$1"
  echo "Updating Client ID to: $CLIENT_ID"

  FILE=src/eireneon/.env
  [ ! -f "$FILE" ] && echo "Error: File $FILE not found" && exit 1
  
  grep -q "^NEXT_PUBLIC_CLIENT_ID=" "$FILE" \
    && sed -i "s/^NEXT_PUBLIC_CLIENT_ID=.*/NEXT_PUBLIC_CLIENT_ID=$CLIENT_ID/" "$FILE" \
    || echo "NEXT_PUBLIC_CLIENT_ID=$CLIENT_ID" >> "$FILE"

  for service in war fury strife death; do
    FILE="src/$service/.env"
    [ ! -f "$FILE" ] && echo "Warning: File $FILE not found" && continue
    
    grep -q "^AUDIENCE=" "$FILE" \
      && sed -i "s/^AUDIENCE=.*/AUDIENCE=$CLIENT_ID/" "$FILE" \
      || echo "AUDIENCE=$CLIENT_ID" >> "$FILE"
  done

  docker compose -f compose/compose.yaml up -d fury death strife war eireneon --force-recreate --build
}

update_service_token() {
  TOKEN="$1"
  FILE="src/war/.env"

  [ ! -f "$FILE" ] && echo "Error: File $FILE not found" && exit 1
  
  echo "Updating service token in $FILE"
  grep -q "^SERVICE_TOKEN=" "$FILE" \
    && sed -i "s/^SERVICE_TOKEN=.*/SERVICE_TOKEN=$TOKEN/" "$FILE" \
    || echo "SERVICE_TOKEN=$TOKEN" >> "$FILE"
  
  echo "Verification:"
  grep "^SERVICE_TOKEN=" "$FILE"

  docker compose -f compose/compose.yaml up -d war --force-recreate
}

# Handle command line arguments
case "$1" in
    initialize)
        initialize
        ;;
    update_client_id)
        [ -z "$2" ] && echo "Error: Missing client ID" && exit 1
        update_client_id "$2"
        ;;
    update_service_token)
        [ -z "$2" ] && echo "Error: Missing token" && exit 1
        update_service_token "$2"
        ;;
    *)
        echo "Usage: $0 {initialize|update_client_id <client_id>|update_service_token <token>}"
        exit 1
esac
