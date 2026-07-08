# Project Plan & Roadmap
## Master Colloquium B — IaC vs Manual AWS Provisioning

**Planning Date:** July 7, 2026
**Presentation Deadline:** July 15, 2026 *(8 days total, ~4 working days to complete all work)*
**Report Deadline:** September 13, 2026

---

## 1. Situation Analysis

### What Exists

| Item | Status | Notes |
|---|---|---|
| Research question | ✅ Defined | IaC (Terraform) vs manual provisioning on AWS |
| WSL2 / Terraform environment | ✅ Set up | Terraform v1.15.6, AWS CLI v2.35.9, Git 2.43 — verified in WSL2 |
| Baseline run | ✅ Done | Manual: 01:17:40, Terraform: 00:20:00 — *but only basic VPC/EC2 scope* |
| Terraform 3-tier code | ✅ Done | All 4 modules (`vpc`, `security`, `database`, `compute`) written, validated, applied successfully |
| 3-tier manual deployment | ✅ Done | Executed 2026-07-08. ~116 min elapsed, 3 config errors, verified `/health` + `/` → 200. See `note.md`. |
| 3-tier Terraform deployment | ✅ Done | Executed 2026-07-08. `terraform apply`: 15m22.122s exact, 38 resources, 1 pre-apply error (caught by `plan`, zero cloud impact), verified `/health` + `/` → 200, drift check passed ("No changes"). See `note.md`. |
| Report draft | ⚠️ Updated | `docs/report.md` now covers the full 3-tier results (§4–§6); rollback/teardown timing and cost-explorer reconciliation still outstanding (§7 Outlook) |
| Teardown (both environments) | ❌ Pending | `manual-*` and `tf-*` resources still live as of this update — screenshots pending capture before teardown (see `docs/manual-deployment-screenshots.md`) |
| Presentation deck | ❌ Missing | Not started |
| Project definition form | ❌ Missing | Required for Moodle submission |

### What the Guidelines Require

The report must address **all 7 sections**. The presentation (constrained by time) should cover **sections 1–4 and 7** per Prof. Purat's guidance.

| # | Section | Status |
|---|---|---|
| 1 | Context / Introduction / Resources | ✅ Updated in `report.md` §1–§2 |
| 2 | Target / Problem / Question | ✅ Updated in `report.md` §1 |
| 3 | Requirements / Criteria / Definitions | ✅ Metrics table formalised in `report.md` §4.1 |
| 4 | Functional Designs / Concepts | ✅ Documented in `architecture.md`; referenced in `report.md` §2 |
| 5 | Implementation / Simulation / Analysis | ✅ 3-tier built and measured for both environments — `report.md` §4.2–§4.5 |
| 6 | Tests / Verification / Results | ✅ Both environments verified end-to-end (`/health`, `/`) — `report.md` §6; screenshot evidence checklist in `docs/manual-deployment-screenshots.md` |
| 7 | Outlook | ✅ Drafted in `report.md` §7 — rollback timing + cost reconciliation still pending |

### Scope Decision

The **baseline run** (VPC/EC2 only) is treated as the **learning/pilot phase**. Its data is retained as a supporting reference but is **not** the primary experiment.

The **primary experiment** is the full **3-Tier Architecture** deployment (VPC × 2 AZs, ALB, Auto Scaling Group, Multi-AZ RDS MySQL), which provides sufficient complexity to justify the 100-hour workload requirement and produce meaningful comparative data.

---

## 2. Architecture Design

### Target: Production-Grade 3-Tier Web Architecture (`eu-central-1`)

```
Internet
    │
    ▼
[Internet Gateway]
    │
    ▼
[Application Load Balancer]  ← Public Subnets (eu-central-1a, eu-central-1b)
    │
    ▼
[Auto Scaling Group — t3.micro EC2]  ← Private App Subnets
  │  Node.js Express API (user-data bootstrap)
    │
    ▼
[RDS MySQL — Multi-AZ]  ← Private DB Subnets
```

**Network layout:**

| Subnet | CIDR | AZ | Purpose |
|---|---|---|---|
| Public A | 10.0.1.0/24 | eu-central-1a | ALB, NAT GW |
| Public B | 10.0.2.0/24 | eu-central-1b | ALB |
| Private App A | 10.0.3.0/24 | eu-central-1a | EC2 (ASG) |
| Private App B | 10.0.4.0/24 | eu-central-1b | EC2 (ASG) |
| Private DB A | 10.0.5.0/24 | eu-central-1a | RDS primary |
| Private DB B | 10.0.6.0/24 | eu-central-1b | RDS standby |

**Security Group chain:** `Internet → ALB-SG (80/443) → EC2-SG (4000 from ALB) → RDS-SG (3306 from EC2)`

**Naming convention for isolation:**
- Terraform resources: `tf-*` prefix
- Manual resources: `manual-*` prefix
- Separate CIDR blocks to avoid overlap

### Terraform Module Structure

```
terraform/
├── main.tf              # Root: calls all modules
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── modules/
    ├── vpc/             # VPC, subnets, IGW, NAT GW, route tables
    ├── security/        # All security groups
    ├── compute/         # ALB, ASG, launch template, user-data
    └── database/        # RDS subnet group, RDS instance
```

### Metrics for Comparison

| Metric | Manual Measurement | Terraform Measurement |
|---|---|---|
| **Deployment Speed** | Stopwatch from first console click to app responding on ALB DNS | Exact `terraform apply` wall-clock time (logged output) |
| **Consistency / Drift** | Count of manual errors, misconfigurations, re-do steps | `terraform plan` re-runs: expected output is "No changes" |
| **Auditability** | Manual changelog notes | `terraform.tfstate` + version-controlled `.tf` files |
| **Rollback Complexity** | Manual teardown time (console) | `terraform destroy` wall-clock time |

---

## 3. Day-by-Day Roadmap

### Day 1 — July 7 (Today): Code & Architecture

**Goal:** All Terraform code written and validated locally.

- [x] Write `modules/vpc` — VPC, 6 subnets, IGW, NAT GW, route tables
- [x] Write `modules/security` — 3 security groups with least-privilege rules
- [x] Write `modules/compute` — Launch template (user-data script), ALB, target group, ASG
- [x] Write `modules/database` — DB subnet group, RDS MySQL Multi-AZ instance
- [x] Write root `main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars`
- [x] Write EC2 user-data Bash script: apt update → install Node.js → deploy custom app (`index.js` + `package.json`) → inject DB config via env vars (systemd unit) → `npm install` → start `node index.js` (app on :4000)
- [x] Run `terraform validate` and `terraform plan` to confirm zero errors
- [x] Document architecture decisions in section 4 of the report

---

### Day 2 — July 8: Manual Deployment + Terraform Deployment

**Goal:** Execute both deployments and capture all empirical data.

**Morning — Manual (Click-Ops) Run:**
- [x] Start stopwatch at VPC creation screen
- [x] Provision: VPC → 6 subnets → IGW → NAT GW → route tables → 3 SGs → ALB → target group → Launch template → ASG → RDS subnet group → RDS instance
- [x] Record: total elapsed time (~116 min, estimated — see `note.md`), 3 configuration errors, rework needed for all 3
- [ ] Capture screenshots of the AWS console at key milestones — checklist ready in `docs/manual-deployment-screenshots.md`, capture still pending
- [x] Stop stopwatch when ALB DNS returns HTTP 200 from the Node.js app (`/health` and `/` both verified)
- [x] Fill in manual row of the results table — see `docs/report.md` §4.1

**Afternoon — Terraform Run:**
- [x] `terraform init` (log output)
- [x] `terraform apply -auto-approve` with `time` prefix to capture exact elapsed time — **15m22.122s**
- [x] Log terraform apply output — 38 resources added, 1 pre-apply error (AMI filter path, caught by `terraform plan`, zero cloud impact)
- [x] Verify: `curl http://<alb_dns>` returns 200 (both `/health` and `/`)
- [x] Run `terraform plan` again → confirmed **"No changes. Your infrastructure matches the configuration."**
- [x] Fill in Terraform row of the results table — see `docs/report.md` §4.1

**Both runs complete → primary data collection done.** ✅ Full results in `docs/report.md` and `note.md`. Screenshot capture and teardown (both environments) are the only remaining pre-report-finalization steps.

---

### Day 3 — July 9: Data Analysis + Report

**Goal:** Full report draft covering all 7 sections.

- [x] Compile all timing data into the comparison tables — `docs/report.md` §4.1–§4.5
- [x] Write section 5 (Implementation) — describe both deployment procedures step by step — covered via `note.md` journal + `report.md` §4
- [x] Write section 6 (Results) — populate all metric tables — `report.md` §4.1, §6; screenshots still to be inserted once captured
- [x] Complete section 3 (Requirements/Criteria/Definitions) with the formal metric definitions — `report.md` §4.1 table
- [x] Complete section 4 (Functional Designs/Concepts) — architecture diagrams and design rationale — `architecture.md` (unchanged, already complete) + `report.md` §2
- [x] Polish sections 1 (Context) and 2 (Target/Problem) — `report.md` §1
- [x] Write section 7 (Outlook) — future work, scalability, CI/CD integration, cost analysis — `report.md` §7 (drafted; rollback timing + cost reconciliation pending actual teardown)
- [ ] Run `terraform destroy` and time the teardown; add to results — **still pending**, both environments currently live for screenshot capture

---

### Day 4 — July 10: Presentation + Final Polish

**Goal:** Presentation deck complete; report near-final.

- [ ] Build presentation covering sections 1–4 and 7 (as per guidelines)
- [ ] Add visual architecture diagram to presentation
- [ ] Create bar charts: deployment time, consistency score, auditability, rollback speed
- [ ] Final review of report — check 8–12 page target
- [ ] Fill out and submit project definition form on Moodle
- [ ] `terraform destroy` both environments (manual teardown of console resources)

**July 11–14: Buffer for revision, rehearsal, presentation refinement.**

---

## 4. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| RDS Multi-AZ takes > 15 min to provision | High | Medium | Start Terraform run early; note this in methodology as an inherent AWS constraint |
| Manual deployment takes > 2h (harder to time accurately) | Medium | Medium | Split into sub-phases with split times; document each leg separately |
| EC2 user-data script fails (Node.js not starting) | Medium | High | Test script on a standalone EC2 first; add `curl ifconfig.me` health check |
| AWS free-tier / billing surprise | Low | Medium | Fund the run with the ~$100 promotional credits (see §7). Non-free-tier resources (Multi-AZ RDS, NAT GW, ALB) cost only a few dollars for a short run; destroy immediately after measurement |
| Terraform version incompatibility with a provider resource | Low | Medium | Pin provider version in `required_providers`; test with `terraform validate` on Day 1 |
| Presentation structure misalignment with guidelines | Low | High | Strictly follow 1–4 + 7 structure; cross-check against Project Guidelines.pdf |

---

## 5. Deliverables Checklist

| Deliverable | Owner | Due |
|---|---|---|
| Terraform module code (all 4 modules) | Dev | July 7 |
| EC2 user-data bootstrap script | Dev | July 7 |
| Manual deployment timing + screenshots | Dev | July 8 |
| Terraform apply timing + state file | Dev | July 8 |
| Full report draft (all 7 sections, 8–12 pages) | Dev | July 9 |
| Presentation deck (sections 1–4 + 7) | Dev | July 10 |
| Project definition form (Moodle) | Dev | July 10 |
| Final report (polished) | Dev | Sept 13 |

---

## 6. Resolved Decisions

1. **Group composition** — ✅ **Solo project.** The project definition form lists a single author.
2. **RDS / cost strategy** — ✅ **Provision → verify → destroy immediately** for both environments. Multi-AZ RDS is retained (it is core to the "production-grade / fault-tolerant" narrative), funded by the ~$100 AWS promotional credits. See the cost estimate in §7.
3. **App-tier verification** — ✅ The payload is a **minimal custom Node.js app** (`app/`, Express + `mysql2`) that we own. Primary success criterion: ALB DNS returns **HTTP 200** on `/health`. Full-chain check: `GET /` runs `SELECT NOW()` against RDS and returns the DB time — proving `ALB → EC2 → RDS` end to end. This swap removes the aws-samples integration issues (config-file rewriting, MySQL 8 auth plugin, schema seeding).
4. **Presentation format** — *(still open)* Slides vs another format — decide before Day 4.

---

## 7. Cost Estimate (funded by ~$100 AWS credits)

Most resources are free-tier eligible, but **three are not**: Multi-AZ RDS, NAT Gateway, and the ALB. For a short-lived experiment (a few hours per environment, then `destroy`), the total cost is negligible and well within the promotional credits.

| Resource | Free tier? | Approx. rate (eu-central-1) | Est. cost for the experiment* |
|---|---|---|---|
| EC2 `t3.micro` × 2 × 2 envs | Yes (750h/mo) | ~$0.012/hr each | ~$0 (within free tier) |
| RDS `db.t3.micro` **Multi-AZ** × 2 envs | **No** (Multi-AZ excluded) | ~$0.068/hr (Multi-AZ) | < $1 |
| NAT Gateway × 2 envs | **No** | ~$0.052/hr + data | < $1 |
| Application Load Balancer × 2 envs | **No** | ~$0.027/hr + LCU | < $1 |
| Elastic IP (attached) | Yes | free while attached | ~$0 |
| VPC / subnets / IGW / route tables / SGs | Yes | free | $0 |
| **Total** | | | **~$2–5** |

*\* Assumes both environments are torn down the same day they are created. The single largest cost driver if left running is the NAT Gateway (~$1.25/day each) and Multi-AZ RDS (~$1.60/day each) — hence the immediate-teardown protocol.*

> **Cost guardrails:**
> - Run `terraform destroy` and manual console teardown **the same day** as each measurement.
> - Set an **AWS Budgets alert** at $10 as an early-warning tripwire.
> - Release any unattached Elastic IPs after teardown (they bill when idle).

---

## 8. Remaining Open Question

- **Presentation format** — Slides (PowerPoint / Google Slides / Marp) or another format? The previous NIDS project used a bullet-dense slide deck. Decision needed before Day 4.
