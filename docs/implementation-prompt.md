# Implementation Prompt for Sonnet — Terraform 3-Tier (TDD)

> Copy everything below the line into a fresh Sonnet session.

---

You are implementing the infrastructure code for a Master Colloquium project that compares Infrastructure-as-Code (Terraform) against manual AWS provisioning. Your job is to **write and test all the code** so the project is ready to deploy. Work **test-first (TDD)** throughout.

## 0. Read first (authoritative spec)

Before writing anything, read these files — they are the source of truth. Do not contradict them:

- `docs/architecture.md` — the full technical design (network, security, resources, user-data, module wiring)
- `docs/plan.md` — scope, decisions, cost constraints, metrics
- `app/index.js`, `app/package.json`, `app/README.md` — the application payload (already written)

If anything in this prompt conflicts with `docs/architecture.md`, follow the doc and flag the conflict.

## 1. Environment

- All commands run in **WSL2 Ubuntu-24.04** (not Windows PowerShell). Prefix with `wsl -d Ubuntu-24.04 -- bash -c "..."` if invoking from Windows.
- Installed & verified: Terraform **v1.15.7**, AWS CLI **v2.35**, Node **v18.20**, npm, git.
- **Do NOT run `terraform apply` or create any real AWS resources.** No credentials should be exercised against the cloud. All testing is offline (`validate`, `fmt`, `plan`-based `terraform test`, and app unit tests).

## 2. What to build

### A. Terraform (`terraform/`)
Four modules plus root config, exactly as specified in `docs/architecture.md` §5:

```
terraform/
├── versions.tf          # required_providers, pinned AWS provider (~> 5.0), TF >= 1.6
├── main.tf              # provider + module calls, wired per the dependency graph
├── variables.tf
├── outputs.tf           # alb_dns_name, rds_endpoint (marked sensitive where needed)
├── terraform.tfvars     # concrete values (see §4)
├── modules/vpc/         # VPC, 6 subnets (2 AZs), IGW, EIP, single NAT GW, route tables + associations
├── modules/security/    # alb-sg, ec2-sg, rds-sg — SG-to-SG references, least privilege
├── modules/database/    # DB subnet group, RDS parameter group, RDS MySQL instance
└── modules/compute/     # ALB, listener :80, target group :4000 (/health), launch template, ASG
    └── user_data.sh.tpl # Ubuntu 22.04 bootstrap; systemd unit; env-var DB config; node index.js
```

### B. App tests (`app/`)
The app is already written. Add a test suite for it (see §3.B).

## 3. TDD workflow — mandatory

Work **one module at a time** in this order (respects the dependency graph): **vpc → security → database → compute → root**. For each module follow the Red-Green-Refactor loop and do **not** move on until it is green.

### A. Terraform modules — use native `terraform test` (`.tftest.hcl`)

For each module, create `modules/<name>/tests/<name>.tftest.hcl` using `command = plan` (plan-only, so **no real resources are created**). 

1. **Red** — write the `.tftest.hcl` assertions first, describing the expected resource attributes (e.g. VPC CIDR, subnet count, SG rules referencing other SGs, RDS engine/multi_az, target group port 4000, health check path `/health`). Run `terraform test` and watch it fail (module not yet written).
2. **Green** — write the minimal HCL in `main.tf`/`variables.tf`/`outputs.tf` to make `terraform validate` pass and the test assertions pass under `terraform test`.
3. **Refactor** — run `terraform fmt`, tidy variable descriptions and defaults, re-run `terraform test` to confirm still green.

Example assertion targets to cover (non-exhaustive — derive the rest from the docs):
- `vpc`: `aws_vpc.this.cidr_block == "10.0.0.0/16"`; exactly 6 subnets; NAT GW count == 1; public RT has `0.0.0.0/0 → igw`.
- `security`: `ec2-sg` ingress port **4000** with `source_security_group_id` == alb-sg; `rds-sg` ingress **3306** from ec2-sg; no `0.0.0.0/0` on ec2-sg or rds-sg ingress.
- `database`: engine `mysql`, `multi_az == true`, `instance_class == "db.t3.micro"`, not publicly accessible.
- `compute`: target group `port == 4000`, `health_check.path == "/health"`; ASG min/max/desired 1/2/2; launch template uses ec2-sg and the user-data template.

Use variable inputs / mock provider blocks in the tests so plan-only runs don't need AWS creds (`provider "aws" { region = "eu-central-1" access_key = "test" secret_key = "test" skip_credentials_validation = true skip_requesting_account_id = true }` in a test override, or Terraform `mock_provider`).

### B. Application — Jest + Supertest

1. **Red** — in `app/`, add `jest`, `supertest`, and add tests in `app/__tests__/app.test.js`:
   - `GET /health` returns **200** and body `OK`.
   - `GET /` with the DB **mocked** (`jest.mock('mysql2/promise')`) returns `200` and JSON containing `status: "connected"` and a `db_time`.
   - `GET /` when the mocked DB throws returns **500** with `status: "db_error"`.
   Refactor `app/index.js` **only if necessary** to make it testable (e.g. export the Express `app` and start `listen` only when run directly). Keep changes minimal.
2. **Green** — implement/adjust until `npm test` passes.
3. **Refactor** — keep it clean; no unused deps.

## 4. Fixed constants (do not deviate)

| Setting | Value |
|---|---|
| Region / AZs | `eu-central-1` / `eu-central-1a`, `eu-central-1b` |
| Terraform VPC CIDR | `10.0.0.0/16` (subnets `10.0.1–6.0/24`) |
| App / target group port | **4000**, health path `/health` |
| ALB listener | HTTP **:80** |
| RDS | MySQL **8.0**, `db.t3.micro`, **Multi-AZ**, port 3306, not public |
| EC2 | `t3.micro`, **Ubuntu 22.04 LTS** AMI (SSM parameter or data source) |
| ASG | min 1 / max 2 / desired 2 |
| Naming prefix | `tf-` (variable `name_prefix`, default `"tf"`) |
| App DB config | via **environment variables** (`DB_HOST/DB_USER/DB_PWD/DB_NAME/PORT`) in a **systemd** unit |
| Secrets | `db_password` as a `sensitive` variable; **never** hardcode; no secrets in outputs/logs |

## 5. Definition of Done

All of the following must pass (offline, no apply):

```bash
cd terraform
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test        # all module .tftest.hcl green (plan-only)

cd ../app
npm install
npm test              # all Jest tests green
```

Then provide a short summary: what each module creates, how the tests are structured, and the exact commands above with their passing output. **Do not run `terraform apply`.**

## 6. Guardrails

- Test-first, always. No implementation HCL/JS before its failing test exists.
- Small commits of work per module; validate after each — do not write all modules then debug.
- No real cloud calls; no `apply`; no credentials against AWS.
- Pin the AWS provider version; keep `terraform fmt` clean.
- If a doc is ambiguous, state your assumption briefly and proceed.
