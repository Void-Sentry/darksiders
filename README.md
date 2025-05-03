# Darksiders Project

A Twitter-like application built with a microservices architecture using Docker, CockroachDB, RabbitMQ, and Zitadel for authentication.

---

## Requirements

* **Node.js**: LTS version
* **Python**: 3.13.3
* **Docker**: 28.0.4
* **Docker Compose**: v2.34.0
* **Docker Desktop**: v4.40.0

---

## Setup Instructions

### 1. Clone the Repository

Clone the repository recursively to include all submodules:

```bash
git clone https://github.com/Void-Sentry/darksiders.git --recursive
cd darksiders
```

---

### 2. Generate CockroachDB Certificates

Use a CockroachDB container to create the necessary certificates for secure communication:

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

---

### 3. Set Up Environment Variables

Copy the example environment files for each submodule:

```bash
git submodule foreach 'cp .env.example .env'
```

---

### 4. Start Services with Docker Compose

Bring up the entire infrastructure:

```bash
docker compose -f compose/compose.yaml up -d
```

---

### 5. Initialize the CockroachDB Cluster

Run the following command to initialize your CockroachDB instance:

```bash
docker exec -it compose-roach1-1 ./cockroach --host roach1:26357 init --certs-dir /run/secrets
```

---

### 6. Set Up a Zitadel Instance

Visit [http://localhost:8080/ui/console](http://localhost:8080/ui/console) to configure Zitadel.

#### 6.1 Initial Credentials

* **Email**: `zitadel-admin@zitadel.localhost`
* **Password**: `Password1!`

#### 6.2 Application Setup (Step-by-Step)

1. Log in to Zitadel using the admin credentials.
2. From the **Dashboard**, create a new **Project**.
3. Inside the project, create a new **Application** with the following settings:

   * **Name**: Any descriptive name
   * **Type**: Web
   * **Authentication Method**: PKCE (Proof Key for Code Exchange)
   * Enable **Development Mode**
   * **Redirect URI**: `http://localhost:8000/callback`
   * **Post Logout URI**: `http://localhost:8000`
4. After creating the application, copy the generated **Client ID**.
5. Paste the **Client ID** into the following `.env` files:

   * `darksiders/src/eireneon/.env`

     ```env
     NEXT_PUBLIC_CLIENT_ID=<PASTE_CLIENT_ID_HERE>
     ```
   * `darksiders/src/war/.env`

     ```env
     AUDIENCE=<PASTE_CLIENT_ID_HERE>
     ```
   * `darksiders/src/fury/.env`

     ```env
     AUDIENCE=<PASTE_CLIENT_ID_HERE>
     ```
   * `darksiders/src/death/.env`

     ```env
     AUDIENCE=<PASTE_CLIENT_ID_HERE>
     ```
   * `darksiders/src/strife/.env`

     ```env
     AUDIENCE=<PASTE_CLIENT_ID_HERE>
     ```

#### 6.3 Create a Service User

1. Go to the **Users** page.
2. Switch to the **Service Users** tab.
3. Create a new **Service User** with a meaningful name.
4. Go to the **Organization** page.
5. Click the blue **Actions** button and select **Add Manager**.
6. In the dialog:

   * Select the new service user in the **Loginname** field.
   * Assign the role: **Org Owner**
   * Click **Add**
7. Go back to the **Service Users** tab.
8. Click on the service user’s name.
9. Navigate to **Personal Access Tokens**.
10. Create a new token and **copy it**.
11. Paste it into `darksiders/src/war/.env` as the value for `SERVICE_TOKEN`.

---

### 7. Recreate All Darksiders Services

Force-recreate specific services to apply any new environment changes:

```bash
cd darksiders
docker compose -f compose/compose.yaml up -d fury death strife war eireneon --force-recreate --build
```

---

### 8. Login with ZITADEL via OIDC (Postman or External Tools)

Use [https://oidcdebugger.com/debug](https://oidcdebugger.com/debug) to acquire an ID token.

OIDC Debugger configuration:

* **Authorize URI**: `http://localhost:8080/oauth/v2/authorize`
* **Client ID**: `292930633691365378` (use your own)
* **Response Type**: `code`
* **Use PKCE**: `SHA-256`
* **Token URI**: `https://localhost:8080/oauth/v2/token`
* **Response Mode**: `form_post`

After submission, go to the **PKCE result** section, and copy the `id_token`. Use this token as a Bearer Token in your API requests.

---

Here is the updated section **9. User Registration (Optional)**, now including a **step-by-step guide to configuring a generic SMTP provider in Zitadel**, with **strong emphasis** on the required email domain:

---

### 9. User Registration (Optional)

> To enable user registration and email verification, configure an SMTP server in your Zitadel instance.

#### 🔧 Configure Generic SMTP Provider in Zitadel

1. Log in to the Zitadel Admin Console at
   **[http://localhost:8080/ui/console](http://localhost:8080/ui/console)**

2. Go to the **Settings** tab in the left menu, then navigate to **SMTP Configurations**.

3. Click on **"Add SMTP Configuration"**.

4. Fill in the configuration fields with the following credentials:

   * **Sender Name**: `zitadel`
   * **Sender Email Address**: `sender@smtp.local`
   * **Reply-To Address**: `replyto@smtp.local`
   * **SMTP Host**: `postfix`
   * **SMTP Port**: `587`
   * **SMTP Username**: `usuario@smtop.local`
   * **SMTP Password**: `senha`
   * **Encryption**: `STARTTLS` or `Unencrypted` (based on how `postfix` is configured)

5. Save the configuration.

6. Set this SMTP configuration as **active**.

#### 📬 Accessing Test Emails

All emails (verification, password reset, etc.) sent by the platform will be visible in the MailDev web UI at:

**➡ [http://localhost:8025](http://localhost:8025)**

Use this during development to inspect sent emails.

---

#### ⚠️ IMPORTANT REQUIREMENT — MUST READ ⚠️

> **Every user account registered in your application MUST use an email address with the domain: `@smtp.local`.**

Zitadel will only be able to send emails (like verification or password resets) to addresses under that domain using the configured SMTP provider.

Example valid emails:

* `john@smtp.local`
* `admin@smtp.local`

Invalid emails (⚠️ won't work):

* `john@gmail.com`
* `user@outlook.com`
