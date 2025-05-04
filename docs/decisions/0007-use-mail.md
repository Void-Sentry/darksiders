# Postfix + Mailpit

## Purpose
Email delivery and debugging stack.

## Why Postfix + Mailpit?
- Postfix handles real email delivery in production environments.
- Mailpit provides a local SMTP server with a web UI for inspecting emails (dev/test).

## Use Cases
- Email verification during signup.
- Notification emails (e.g., "You've got a new follower").

## Justification Summary
This setup provides a full email stack for both production and development. It ensures developers can test email flows locally without sending real emails.
