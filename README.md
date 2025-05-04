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
4. Click the **+ icon button** next to the **blue Actions button**.
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

## 5. User Registration

> To enable user registration and email verification, you must configure an SMTP server in Zitadel.

### 🔧 Configure SMTP in Zitadel

1. Go to **Default settings** > **SMTP Provider** in the Zitadel console.

2. Click **Generic SMTP**.

3. Fill in the fields:

   * **Transport Layer Security (TLS)**: `Unchecked`
   * **Host And Port**: `postfix:587`
   * **User**: `usuario@smtp.local`
   * **Password**: `senha`
   * **Sender Email Address**: `sender@smtp.local`
   * **Sender Name**: `zitadel`
   * **Reply-To Address**: `replyto@smtp.local`
   * **Email Address**`zitadel-admin@smtp.local`

4. Test, create and activate the configuration.

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

---

### 6. Access the Frontend

Navigate to the frontend application to interact with the Darksiders platform.

➡ [http://localhost:8000](http://localhost:8000)

From here, you can:

* **Register new users** using the signup flow.
* **Log in** using Zitadel credentials.
* **Create posts** and share content.
* **Discover other users** on the platform.
* **Follow/unfollow users** to build your social network.

This interface serves as the main entry point for testing and interacting with the Darksiders ecosystem.

---

### 7. Obtain an ID Token Using OIDC Debugger (Postman Only)

To manually obtain an ID token for authenticated API testing (e.g., via Postman), use:

➡ [https://oidcdebugger.com/debug](https://oidcdebugger.com/debug)

**OIDC Debugger Configuration:**

* **Authorize URI**: `http://localhost:8080/oauth/v2/authorize`
* **Client ID**: `<your-client-id>`
* **Response Type**: `code`
* **Use PKCE**: `SHA-256`
* **Token URI**: `https://localhost:8080/oauth/v2/token`
* **Response Mode**: `form_post`

After completing the flow, scroll down to the **PKCE Result** section and copy the generated `id_token`. You can then use this token as a **Bearer token** in the Authorization header when making authenticated API requests.
