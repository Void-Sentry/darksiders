#!/bin/sh

docker run --rm -it -v $(pwd):/app -w /app docker.io/cockroachdb/cockroach:v24.2.1 bash -c "
  cd compose/services/database && \
  cockroach cert create-ca --certs-dir=./ --ca-key=ca.key && \
  for node in roach1 roach2 roach3; do \
    cockroach cert create-node \$node roach-lb --certs-dir=./ --ca-key=ca.key && \
    mkdir -p node\${node: -1}/certs && mv node.* node\${node: -1}/certs; \
  done && \
  for client in root zitadel fury strife death war; do \
    cockroach cert create-client \$client --certs-dir=./ --ca-key=ca.key && \
    mkdir -p clients/\$client && mv client.* clients/\$client; \
  done && \
  chown 1000:1000 -R ."

git submodule foreach 'cp .env.example .env'

docker compose -f compose/compose.yaml up -d

sleep 10

docker exec -it compose-roach1-1 ./cockroach --host roach1:26357 init --certs-dir /run/secrets
