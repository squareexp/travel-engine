# Secrets and configuration

Local development uses ignored `.env` files. Copy values from `infra/.env.example`, replacing every placeholder before connecting to a shared environment. Staging and production secrets are injected by the hosting platform or CI secret store, never committed or printed in logs.

The API fails at startup when required database or JWT configuration is absent. Credentials, payment tokens, full phone numbers, password hashes, authorization headers, and raw webhook payloads must not be logged or sent to error tracking.

When a secret is exposed outside its intended boundary, rotate it at the provider first, update the secret store, deploy, and verify the old credential no longer works. Treat local `server/.env` and `client/.env` as sensitive files even when the repository is not currently initialized as Git.
