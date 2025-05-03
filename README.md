# Darksiders Project

This project provides a "Twitter" using a microservices architecture with Docker, CockroachDB, and RabbitMQ.

## Requirements

- **Node.js**: LTS
- **Python**: 3.13.3
- **Docker**: Version 28.0.4
- **Docker Compose**: Version v2.34.0

<!-- ## Demo -->

<!-- Access the live demo of this setup at: [desktop-pq51n13.kiko-dorian.ts.net](https://desktop-pq51n13.kiko-dorian.ts.net) -->

### Zitadel
- mail: zitadel-admin@zitadel.localhost
- default pass: Password1!

## Setup Instructions

### 1. Clone the Repository

Clone the repository recursively to include submodules:

```bash
git clone https://github.com/Void-Sentry/darksiders.git --recursive
cd darksiders
```

### 2. Set Up CockroachDB Certificates

Run a CockroachDB container to generate certificates for secure communication:

```bash
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
```

<!-- ### 3. Build Docker Images for Submodules

Build Docker images for each submodule in the project:

```bash
git submodule foreach 'docker buildx build -t $(basename "$name"):latest .'
``` -->

### 3. Start Services with Docker Compose

Start all the services using Docker Compose:

```bash
docker compose -f compose/compose.yaml up -d
```

### 4. Initialize CockroachDB Cluster

Run the following command to initialize the CockroachDB cluster:

```bash
docker exec -it compose-roach1-1 ./cockroach --host roach1:26357 init --certs-dir /run/secrets
```

### 5. Setting Up a Zitadel Instance
- navigate to http://localhost:8080/ui/console

#### 5.1 Initial Credentials
- mail: zitadel-admin@zitadel.localhost
- pass: Password1!

#### 5.2 Set By Step
- First Login: Log in to your Zitadel account for the first time.
- Create a Project: Go to the dashboard and create a new project.
- Add an Application: Within the project, create a new application.
- Name: Give the application a meaningful name.
- Type: Select the "Web" option for the application type.
- Authentication Method: Choose "PKCE" (Proof Key for Code Exchange).
- Set Redirect URI: Add https://oidcdebugger.com/debug as the Redirect URI.
- Copy Client ID: Once configured, copy the Client ID for later use

#### 5.3 Set By Step Service User

### 6. Login with ZITADEL
Use https://oidcdebugger.com/debug as a client to obtain the token.

OIDC Debugger Settings:

- Authorize URI (required): https://localhost/oauth/v2/authorize
- Client ID (required): 292930633691365378
- Response Type (required): code
- Use PKCE?: SHA-256
- Token URI (required for PKCE): https://localhost/oauth/v2/token
- Response Mode (required): form_post

After submitting the form, go to the "PKCE result" section to copy the id_token. - Use this token as a Bearer Token in your requests.

### 7. User Registration
To enable user registration, you need to set up an SMTP server in the ZITADEL instance. This allows for sending verification and password recovery emails, which are essential for the user registration process.
