# 3-Tier Demo App

Minimal Node.js payload for the Master Colloquium B experiment (IaC vs Manual AWS provisioning).

Its only job is to **prove the full 3-tier chain works**: traffic flows `ALB -> EC2 (this app) -> RDS MySQL`.

## Routes

| Route | Purpose |
|---|---|
| `GET /health` | Liveness probe for the ALB target group. Returns `200 OK`. |
| `GET /` | Connects to RDS and runs `SELECT NOW(), VERSION()`. Returns JSON proving DB connectivity. |

## Configuration (environment variables)

| Variable | Description | Example |
|---|---|---|
| `PORT` | Port the app listens on | `4000` |
| `DB_HOST` | RDS endpoint (host only, no port) | `tf-rds.xxxx.eu-central-1.rds.amazonaws.com` |
| `DB_USER` | Database user | `admin` |
| `DB_PWD` | Database password | *(from Terraform variable / secret)* |
| `DB_NAME` | Database name | `mysql` |

> Uses the `mysql2` driver, which natively supports MySQL 8.0's `caching_sha2_password` — no auth-plugin workaround or schema seeding required. `SELECT NOW()` runs against the default `mysql` database, so no table needs to be created.

## Local run

```bash
npm install
DB_HOST=... DB_USER=admin DB_PWD=... DB_NAME=mysql npm start
```
