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
git clone https://github.com/Void-Sentry/darksiders.git --recursive && cd darksiders
```

---

### 2. Grant Execute Permission to Setup Script

```bash
chmod +x setup.sh
```

---

### 3. Run Initial Setup

```bash
./setup.sh initialize
```

---

### 4. Set Up Zitadel Instance

Visit the console at:
➡ [http://localhost:8080/ui/console](http://localhost:8080/ui/console)

#### 4.1 Initial Admin Credentials

* **Email**: `zitadel-admin@zitadel.localhost`
* **Password**: `Password1!`

#### 4.2 Configure a Web Application

1. Log in with the admin credentials.
2. Create a new **Project**.
3. Inside the project, add a new **Application** with the following settings:

   * **Name**: Any descriptive name
   * **Type**: Web
   * **Authentication Method**: PKCE (Proof Key for Code Exchange)
   * Enable **Development Mode**
   * **Redirect URI**: `http://localhost:8000/callback`
   * **Post Logout URI**: `http://localhost:8000`
4. After creating the application, copy the generated **Client ID**.
5. Run the command below, replacing `<CLIENT_ID>` with the one you copied:

```bash
./setup.sh update_client_id <CLIENT_ID>
```

---

#### 4.3 Create a Service User

1. Navigate to **Users** > **Service Users** tab.
2. Create a new service user with a meaningful name.
3. Go to the **Organization** section.
4. Click the **Actions** button and select **Add Manager**.
5. In the dialog:

   * Select the service user under **Loginname**
   * Assign the role: **Org Owner**
   * Click **Add**
6. Return to **Service Users**, select the user.
7. Go to **Personal Access Tokens**
8. Create a new token and copy it.
9. Run the command below, replacing `<SERVICE_TOKEN>` with the copied token:

```bash
./setup.sh update_service_token <SERVICE_TOKEN>
```

---

### 5. Login via ZITADEL (OIDC)

To obtain an ID token for testing, use:
➡ [https://oidcdebugger.com/debug](https://oidcdebugger.com/debug)

**OIDC Debugger Configuration:**

* **Authorize URI**: `http://localhost:8080/oauth/v2/authorize`
* **Client ID**: `<your-client-id>`
* **Response Type**: `code`
* **Use PKCE**: `SHA-256`
* **Token URI**: `https://localhost:8080/oauth/v2/token`
* **Response Mode**: `form_post`

After completing the flow, copy the `id_token` from the **PKCE Result** section and use it as a Bearer token in your API requests.

---

## 6. User Registration (Optional)

> To enable user registration and email verification, you must configure an SMTP server in Zitadel.

### 🔧 Configure SMTP in Zitadel

1. Go to **Settings** > **SMTP Configurations** in the Zitadel console.

2. Click **Add SMTP Configuration**.

3. Fill in the fields:

   * **Sender Name**: `zitadel`
   * **Sender Email Address**: `sender@smtp.local`
   * **Reply-To Address**: `replyto@smtp.local`
   * **SMTP Host**: `postfix`
   * **SMTP Port**: `587`
   * **SMTP Username**: `usuario@smtp.local`
   * **SMTP Password**: `senha`
   * **Encryption**: `STARTTLS` or `Unencrypted` (based on `postfix` config)

4. Save and activate the configuration.

### 📬 View Test Emails

All outgoing emails (e.g., verifications, resets) can be viewed via MailPit:
➡ [http://localhost:8025](http://localhost:8025)

---

### ⚠️ Required Email Domain for Registration

> **Only emails using the `@smtp.local` domain will work for user registration and verification.**

✅ Valid Examples:

* `john@smtp.local`
* `admin@smtp.local`

❌ Invalid (won't work):

* `john@gmail.com`
* `user@outlook.com`
