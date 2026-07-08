# Deployment Evidence — Screenshot & Capture Checklist (Manual + Terraform)

**Purpose:** Capture visual and CLI-based proof of the completed **manual (Click-Ops)** and **Terraform (IaC)** 3-tier deployments for use in `docs/report.md` (§4–§6) and the presentation deck. Both environments (`manual-*` and `tf-*`) were verified working end-to-end on 2026-07-08 and are currently **still live**, awaiting this capture step before teardown.

> Cross-reference: the full timing/decision/error journal for both runs is in `note.md` (repo root). This file is only about *what to capture and why*.

---

## How to use this document

1. Work through **Part A (Manual)** first, then **Part B (Terraform)** — both environments are live simultaneously right now, so either order works, but capture Tier 1 of both before anything else in case one environment needs to be torn down first (e.g. for cost reasons).
2. Save screenshots into `docs/presentation/screenshots/manual/` and `docs/presentation/screenshots/terraform/` respectively, named per the numbering below (e.g. `01-health-curl.png`, `02-asg-instances.png`, …).
3. For each screenshot, jot one line about what it proves — this speeds up writing the report later.
4. Once Tier 1 + Tier 2 are captured for **both** environments, proceed to teardown (order given at the bottom) to stop the AWS billing clock.

---

# Part A — Manual (`manual-*`) Environment

## Tier 1 — Must-have (proof of success)

| # | Screenshot | Where to find it | What it proves |
|---|---|---|---|
| 1 | Terminal/curl output for `/health` (→ `OK`, HTTP 200) and `/` (→ JSON with `db_time`, HTTP 200) | Your terminal (WSL) running the `curl` commands against `manual-alb`'s DNS | End-to-end chain `ALB → EC2 → RDS` works. Already captured programmatically — see §"Already-captured evidence" below. |
| 2 | ASG detail page | EC2 → Auto Scaling Groups → `manual-asg` → **Instance management** tab | 2/2 desired instances, both `InService`, both `Healthy` |
| 3 | Target Group health page | EC2 → Target Groups → `manual-tg` → **Targets** tab | Both targets `healthy` on port 4000 (app-level health, not just EC2-level) |
| 4 | ALB detail page | EC2 → Load Balancers → `manual-alb` → **Description** tab | State `Active`, DNS name visible, listener :80 configured |

## Tier 2 — Architecture proof (for presentation diagrams/evidence)

| # | Screenshot | Where to find it | What it proves |
|---|---|---|---|
| 5 | VPC Resource Map | VPC console → **Your VPCs** → `manual-vpc` → **Resource map** tab | Whole topology in one diagram: subnets, route tables, IGW, NAT GW — great visual for slides |
| 6 | RDS instance detail page | RDS → Databases → `manual-rds` → **Connectivity & security** / **Configuration** tabs | Status `Available`, Multi-AZ `Yes`, engine MySQL 8.0, instance class `db.t3.micro` |
| 7 | Security Groups list + rules | VPC → Security Groups → select each of `manual-alb-sg`, `manual-ec2-sg`, `manual-rds-sg` → **Inbound rules** tab | Proves the SG-to-SG chain (ALB←Internet, EC2←ALB-SG, RDS←EC2-SG), the "least-privilege" design from `architecture.md` §3 |

## Tier 3 — Supporting detail (nice-to-have, drift/error discussion)

| # | Screenshot | Where to find it | What it proves |
|---|---|---|---|
| 8 | Route tables (public + private), post-fix | VPC → Route Tables → `manual-rt-public` and `manual-rt-private` → **Routes** tab | Correct `0.0.0.0/0` targets (IGW vs NAT GW) — ties into the Step 5 error/fix story documented in `note.md` |
| 9 | Billing/Credits page | Billing and Cost Management → **Credits** | Shows minimal actual cost impact of the run — supports `report.md` §7 cost discussion |
| 10 | EC2 Instances list | EC2 → Instances | Both instances running, spread across `eu-central-1a`/`eu-central-1b`, private IPs only (no public IP) — proves cross-AZ + private-subnet design |
| 11 | RDS "Free Plan" upgrade prompt / billing screen | Billing and Cost Management, at the point of the account-upgrade detour | Documents Error #2 from `note.md` — the AWS Free Plan blocking Multi-AZ RDS creation, a real-world manual-deployment friction point worth showing in the presentation |
| 12 | RDS wizard default instance class before correction (`db.m7g.large` / io2 / 400GiB) | *(only if reproducible — otherwise rely on the CLI/journal record)* | Documents Error #3 — the oversized default that had to be manually corrected |

---

# Part B — Terraform (`tf-*`) Environment

## Tier 1 — Must-have (proof of success)

| # | Screenshot / capture | Where to find it | What it proves |
|---|---|---|---|
| 1 | Full terminal output of `time terraform apply -auto-approve` | Your WSL terminal history / `/tmp/tf_apply.log` on the WSL filesystem | The exact **15m22.122s** timing, `Apply complete! Resources: 38 added, 0 changed, 0 destroyed`, and the `alb_dns_name` / `rds_endpoint` outputs — this is the single most important piece of evidence for the whole experiment |
| 2 | Terminal output of the **failed** first `terraform plan` (AMI error) | `/tmp/tf_plan.log` or scroll back in terminal history | Shows `Error: Your query returned no results` — direct proof that Terraform caught a config error before touching any resource |
| 3 | Terminal output of the **successful** second `terraform plan` (`Plan: 38 to add, 0 to change, 0 to destroy`) | Same as above, post AMI fix | Shows the fix worked and quantifies exactly what will be created, before creating it |
| 4 | Terminal output of the post-apply `terraform plan` drift check (`No changes. Your infrastructure matches the configuration.`) | Terminal history | The single clearest piece of evidence for the "consistency/auditability" research question — no manual equivalent exists |
| 5 | `curl` output for `/health` and `/` against `tf-alb`'s DNS | Terminal history | Same end-to-end verification as the manual run, for direct side-by-side comparison |
| 6 | ASG detail page | EC2 → Auto Scaling Groups → `tf-asg` → **Instance management** tab | 2/2 desired instances, both `InService`/`Healthy` — direct visual parity with manual Tier 1 #2 |
| 7 | Target Group health page | EC2 → Target Groups → `tf-tg` → **Targets** tab | Both targets `healthy` on port 4000 — direct visual parity with manual Tier 1 #3 |

## Tier 2 — Architecture proof

| # | Screenshot | Where to find it | What it proves |
|---|---|---|---|
| 8 | VPC Resource Map | VPC console → **Your VPCs** → `tf-vpc` → **Resource map** tab | Same topology as `manual-vpc` but built declaratively — good side-by-side slide with manual Tier 2 #5 |
| 9 | RDS instance detail page | RDS → Databases → `tf-rds` → **Configuration** tab | Status `Available`, Multi-AZ `Yes`, MySQL `8.0.46`, `db.t3.micro` — note the DB engine **patch version differs slightly** from the manual run's `8.4.9` (AWS's "current" MySQL 8.0 minor version can drift between provisioning times even with identical `engine_version = "8.0"` — worth a one-line callout in the report as a subtlety of version pinning) |
| 10 | Terraform state file listing (`terraform state list`) | Run in the `terraform/` directory | Enumerates all 38 managed resources — direct proof of the "auditability" advantage (version-controlled, inspectable state vs. manual's console-only record) |
| 11 | `terraform/` directory / module structure in an editor or `tree` output | Local repo | Visual proof of the declarative, version-controlled codebase — good contrast slide against 12 manual console screenshots |

## Tier 3 — Supporting detail

| # | Screenshot | Where to find it | What it proves |
|---|---|---|---|
| 12 | Security Groups list (`tf-alb-sg`, `tf-ec2-sg`, `tf-rds-sg`) with rules | VPC → Security Groups | Same SG-to-SG chain as manual, generated automatically and identically every time — zero risk of the Step 5/6-style manual mixup |
| 13 | Git commit history (`git log --oneline`) touching `terraform/` | Local repo | Shows the AMI-filter fix as a real, timestamped, auditable code change — contrast with the manual run's fixes being invisible/undocumented except in `note.md` |

---

## Already-captured evidence (both environments — text, no screenshot needed)

These were captured live during the deployment session and are already recorded in `note.md` — safe to paste directly into the report as code blocks without re-capturing:

```text
# Manual environment verification
curl http://manual-alb-570599602.eu-central-1.elb.amazonaws.com/health
→ OK  (HTTP 200)
curl http://manual-alb-570599602.eu-central-1.elb.amazonaws.com/
→ {"status":"connected","tier":"app -> database","db_time":"2026-07-08T18:13:49.000Z","db_version":"8.4.9"}  (HTTP 200)

# Terraform environment verification
curl http://tf-alb-1052327157.eu-central-1.elb.amazonaws.com/health
→ OK  (HTTP 200)
curl http://tf-alb-1052327157.eu-central-1.elb.amazonaws.com/
→ {"status":"connected","tier":"app -> database","db_time":"2026-07-08T19:35:36.000Z","db_version":"8.0.46"}  (HTTP 200)

# Terraform apply (exact timing)
Apply complete! Resources: 38 added, 0 changed, 0 destroyed.
alb_dns_name = "tf-alb-1052327157.eu-central-1.elb.amazonaws.com"
rds_endpoint = <sensitive>
real    15m22.122s

# Terraform drift check (post-apply)
No changes. Your infrastructure matches the configuration.
```

---

## Optional: CLI-based backup evidence commands

If a screenshot is missed or a resource gets torn down early, these AWS CLI / Terraform commands (run from WSL2) reproduce the same evidence as text/JSON, pastable into the report as a code block. Substitute `manual-` ↔ `tf-` prefixes as needed.

```bash
# ASG instance health
export AWS_PAGER=""
aws autoscaling describe-auto-scaling-instances --region eu-central-1 --output table

# Target group health
aws elbv2 describe-target-health --region eu-central-1 --target-group-arn <target-group-arn> --output table

# ALB state
aws elbv2 describe-load-balancers --region eu-central-1 --names manual-alb --output table
aws elbv2 describe-load-balancers --region eu-central-1 --names tf-alb --output table

# RDS status
aws rds describe-db-instances --region eu-central-1 --db-instance-identifier manual-rds --output table
aws rds describe-db-instances --region eu-central-1 --db-instance-identifier tf-rds --output table

# curl verification
curl -s -w "\nHTTP_STATUS:%{http_code}\n" http://<alb-dns>/health
curl -s -w "\nHTTP_STATUS:%{http_code}\n" http://<alb-dns>/

# Terraform-only: full managed resource inventory
cd terraform
terraform state list

# Terraform-only: re-run drift check any time
terraform plan   # expect: "No changes. Your infrastructure matches the configuration."
```

---

## After screenshots are captured — Teardown

Once Tier 1 + Tier 2 are captured for **both** environments, tear both down the same day (per `docs/plan.md` §7 cost guardrail — Multi-AZ RDS, NAT Gateway, and ALB all bill hourly, in **both** environments simultaneously right now).

### Terraform teardown (timed, for the rollback metric)

```bash
cd terraform
export TF_VAR_db_password="<same password used for apply>"
time terraform destroy -auto-approve
```

Record the `real` time from `time` output into `note.md` and `docs/report.md` §5 (rollback complexity metric).

### Manual teardown (reverse order of creation)

1. Delete Auto Scaling Group (`manual-asg`) — terminates instances
2. Delete Launch Template (`manual-lt`)
3. Delete ALB (`manual-alb`) + Target Group (`manual-tg`)
4. Delete RDS instance (`manual-rds`) — skip final snapshot
5. Delete DB Subnet Group (`manual-db-subnet-group`)
6. Delete NAT Gateway (`manual-natgw`) — wait for deletion before releasing EIP
7. Release Elastic IP
8. Delete Route Tables (`manual-rt-public`, `manual-rt-private`)
9. Delete Security Groups (`manual-rds-sg` → `manual-ec2-sg` → `manual-alb-sg`, in that dependency order)
10. Detach + delete Internet Gateway (`manual-igw`)
11. Delete 6 subnets
12. Delete VPC (`manual-vpc`)

Time this teardown too (stopwatch), for direct comparison against the Terraform `destroy` timing — this is the "Rollback Complexity" metric from `architecture.md` §5's methodology.

**After both teardowns:** verify a clean slate again (`aws ec2 describe-vpcs`, `describe-instances`, `rds describe-db-instances`, `describe-nat-gateways`, `describe-addresses` — all should return empty/terminated), and check the AWS Billing Credits page one more time to record final cost impact for `docs/report.md` §7.
