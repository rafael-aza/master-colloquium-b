# Master Colloquium B — IaC vs Manual AWS Provisioning

A comparative study of **Infrastructure as Code (Terraform)** versus **manual AWS Console provisioning** ("Click-Ops"), measured across deployment speed, configuration consistency, auditability, and rollback complexity.

**Supervisor:** Prof. Dr.-Ing. Marcus Purat
**Region:** `eu-central-1` (Frankfurt)

## Research Question

> To what extent does IaC (Terraform) improve the deployment speed and operational consistency of AWS cloud resources compared to manual provisioning?

## What Gets Deployed

A production-shaped **3-tier web architecture**, deployed twice (once via Terraform, once by hand) for comparison:

- **Network:** VPC across 2 AZs — 6 subnets (public / private-app / private-db), Internet Gateway, NAT Gateway
- **Compute:** Application Load Balancer → Auto Scaling Group of `t3.micro` EC2 instances
- **Data:** Multi-AZ Amazon RDS MySQL 8.0
- **Payload:** A minimal Node.js (Express + `mysql2`) app that proves the full chain `ALB → EC2 → RDS`

See [docs/architecture.md](docs/architecture.md) for the full design and diagrams.

## Repository Layout

```
.
├── app/                    # Node.js payload (single source of truth; EC2 clones this at boot)
│   ├── index.js            # Express app: /health and / (SELECT NOW())
│   ├── package.json
│   └── __tests__/          # Jest + Supertest unit tests
├── terraform/              # Infrastructure as Code
│   ├── main.tf             # Root: provider + module wiring
│   ├── variables.tf / outputs.tf / terraform.tfvars / versions.tf
│   ├── modules/            # vpc · security · database · compute
│   └── tests/              # terraform test (.tftest.hcl), plan-only
├── scripts/                # Helper scripts (local smoke test, etc.)
└── docs/                   # plan.md · architecture.md · report.md · guidelines
```

## Prerequisites

Verified in **WSL2 Ubuntu**:

| Tool | Version |
|---|---|
| Terraform | 1.15.7 |
| AWS CLI | 2.35 |
| Node.js | 18.20 |
| Git | 2.43 |

AWS credentials configured (`aws configure`) with permissions for VPC, EC2, ELB, RDS, and IAM.

## Usage

### Test (offline — no cloud resources, no cost)

```bash
# Terraform: format, validate, and plan-based module tests
cd terraform
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test

# App unit tests
cd ../app
npm install
npm test
```

### Deploy

```bash
cd terraform
export TF_VAR_db_password="<choose-a-strong-password>"
terraform init
time terraform apply         # timed for the deployment-speed metric

# Verify the full 3-tier chain
curl "http://$(terraform output -raw alb_dns_name)/"        # -> {"status":"connected", ...}
curl "http://$(terraform output -raw alb_dns_name)/health"  # -> OK

# Drift check (should report: No changes)
terraform plan
```

### Tear Down

```bash
terraform destroy            # timed for the rollback metric
```

> **Cost note:** Multi-AZ RDS, NAT Gateway, and the ALB are **not** free-tier eligible. A same-day provision→measure→destroy run costs ~$2–5, covered by AWS promotional credits. Always destroy the same day and keep an AWS Budgets alert set. See [docs/plan.md](docs/plan.md) §7.

## Documentation

- [docs/plan.md](docs/plan.md) — roadmap, decisions, cost estimate, metrics
- [docs/architecture.md](docs/architecture.md) — technical design and diagrams
- [docs/report.md](docs/report.md) — academic report

## License

MIT
