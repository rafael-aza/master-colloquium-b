# Project Report: Comparative Analysis of Cloud Infrastructure Provisioning

**Date:** July 7–8, 2026

**Project Scope:** Master Colloquium B

**Supervisor:** Prof. Dr.-Ing. Marcus Purat

**Status:** Both primary experiment runs (manual 3-tier and Terraform 3-tier) are complete with verified end-to-end results. This report covers the full 3-tier architecture experiment; the earlier VPC/EC2-only baseline run is retained in §3.1 as supporting context only.

---

## 1. Introduction

Modern cloud environments require scalable, reliable, and repeatable infrastructure deployment strategies. This project investigates the transition from traditional manual provisioning ("Click-Ops") to automated Infrastructure as Code (IaC) methodologies. The primary research question is:

> To what extent does IaC (Terraform) improve deployment speed and operational consistency of AWS cloud resources compared to manual provisioning?

The experiment provisions a **production-shaped 3-tier web architecture** (public ALB tier, private compute tier, private data tier) twice — once entirely by hand through the AWS Management Console, and once declaratively via Terraform — using isolated CIDR blocks and naming prefixes so both environments can coexist without interference. Full architectural rationale is in `docs/architecture.md`; the day-by-day plan and cost model are in `docs/plan.md`.

## 2. Technical Architecture & Environment

The deployment environment was established using **WSL2 Ubuntu 24.04**, with the `eu-central-1` (Frankfurt) region as the target for both comparative runs.

| Tool | Version |
|---|---|
| Terraform | 1.15.6 |
| AWS CLI | 2.35.9 |
| Git | 2.43.0 |
| Node.js (on EC2, via user-data) | 18.x (NodeSource) |

* **Cloud Provider:** Amazon Web Services (AWS)
* **Instance specification:** `t3.micro` (identical in both environments, for 1:1 hardware parity)
* **Base AMI:** Ubuntu **24.04 LTS** ("noble"), Canonical, `hvm-ssd-gp3` image family — see §4.4 for why this differs from the originally planned 22.04
* **Resource scope (per environment):** VPC across 2 AZs, 6 subnets (public / private-app / private-db), Internet Gateway, NAT Gateway, 3 security groups, Application Load Balancer + target group, Auto Scaling Group of EC2 instances, Multi-AZ RDS MySQL 8.0 — **38 AWS resources** in the Terraform run; an equivalent set created manually.
* **Application payload:** a minimal Node.js (Express + `mysql2`) app (`app/`) exposing `/health` (liveness) and `/` (runs `SELECT NOW()` against RDS, proving the full `ALB → EC2 → RDS` chain).

## 3. Methodology: Comparative Analysis

Both environments were built to the **identical specification** in `docs/architecture.md` — same instance types, same Multi-AZ RDS configuration, same security-group chain, same application — differing only in *how* they were provisioned. Full field-by-field build logs, decisions, and timing for both runs are preserved in `note.md` at the repository root.

### 3.1 Baseline Run (Pilot, VPC/EC2 only — retained for context)

An earlier, smaller-scope pilot (VPC + single EC2 instance only, no 3-tier architecture) was run prior to the primary experiment to validate the local tooling:

| Metric | Manual (AWS Console) | Automated (Terraform) |
| --- | --- | --- |
| Deployment Time | 01:17:40 | 00:20:00 |

This baseline is **not** the primary experiment — it lacks the ALB/ASG/Multi-AZ RDS complexity of the full architecture — but is retained as supporting evidence that the directional finding (Terraform faster, more consistent) held even at small scale.

### 3.2 Primary Experiment — 3-Tier Architecture

**Manual run:** timed via stopwatch from the first console click (VPC creation) through the final `curl` verification against the ALB DNS name returning HTTP 200 on both `/health` and `/`.

**Terraform run:** timed precisely via `time terraform apply -auto-approve`, from `terraform init`/`plan` through `Apply complete!`, followed by the same `curl` verification and a post-apply `terraform plan` drift check.

## 4. Results

### 4.1 Headline Comparison

| Metric | Manual (Click-Ops) | Terraform (IaC) |
|---|---|---|
| **Total deployment time** | ~116 minutes (1h 56m) *(estimated — see §4.2 caveat)* | **15 minutes 22.122 seconds** *(exact, measured)* |
| **Speed multiplier** | 1× (baseline) | **~7.5× faster** |
| **Configuration errors / detours** | 3 | 1 |
| **Errors caught before touching cloud resources** | 0 of 3 (all discovered mid-build, in the console) | 1 of 1 (caught entirely by `terraform plan`, zero resources touched) |
| **Verification** | `/health` → `200 OK`; `/` → `200` with live `db_time` from RDS | `/health` → `200 OK`; `/` → `200` with live `db_time` from RDS |
| **Drift check** | No equivalent tooling exists for manual console work | `terraform plan` → **"No changes. Your infrastructure matches the configuration."** |
| **Resources provisioned** | ~28 (VPC, 6 subnets, IGW, NAT GW+EIP, 2 route tables, 3 SGs, ALB+listener+TG, launch template, ASG (2 EC2), DB subnet group, Multi-AZ RDS) | **38** (Terraform counts every sub-resource explicitly, incl. individual SG rules as separate resources) |

### 4.2 Manual Run — Detailed Timing

| Step | Elapsed (cumulative) | Step duration |
|---|---|---|
| T0 — Start (VPC create clicked) | 00:00 | — |
| 1. VPC (`manual-vpc`, `10.1.0.0/16`) | 03:40 | 3m40s |
| 2. 6 subnets + public IP auto-assign | 09:18 | 5m38s |
| 3. Internet Gateway (create + attach) | 11:38 | 2m20s |
| 4. Elastic IP + NAT Gateway | 13:44 | 2m06s |
| 5. Route tables (public → IGW, private → NAT GW) | 24:04 | 10m20s *(incl. 1 error, see §4.3)* |
| 6. Security groups (3, SG-to-SG chained) | 28:54 | 4m50s |
| 7. Target group + ALB | 39:54 | 11m00s |
| *(stopwatch reset — account/billing detour, see §4.3)* | reset | — |
| 8. DB subnet group + Multi-AZ RDS | ≈69:54 | ≈30m *(incl. 2 errors, see §4.3)* |
| 9. Launch template (AMI + user-data) | ≈99:54 | ≈30m |
| 10. Auto Scaling Group | ≈109:54 | ≈10m |
| 11. Verification (`/health`, `/` → 200) | **≈116:00** *(estimated)* | ≈6m |

> **Methodology caveat:** the final verification timestamp was not captured live by the operator; it is estimated as 109:54 + ~6 minutes (typical `t3.micro` boot + user-data bootstrap + 2× ALB health-check interval at 30s). This is flagged transparently rather than presented as an exact figure — a good illustration of how manual timing is itself harder to instrument precisely than an automated tool's wall-clock output.

### 4.3 Manual Run — Errors / Configuration Drift (3 total)

| # | Issue | Step | Discussion |
|---|---|---|---|
| 1 | Private route table's `0.0.0.0/0` route was mistakenly pointed at the **Internet Gateway** instead of the **NAT Gateway**. | Route tables | Exactly matches the "most commonly missed" manual misconfiguration flagged in `docs/architecture.md` §3.2 (SG/route target confusion). Caught by manual inspection, not tooling. |
| 2 | The AWS account was on a restrictive **"Free Plan"** that blocked Multi-AZ RDS creation outright, requiring a one-time account upgrade to a standard paid plan (offset by existing promotional credits) before the deployment could continue. | RDS creation | Pure manual-deployment friction with no Terraform equivalent — an account-tier gotcha specific to newer/free-tier AWS accounts, not part of the architecture itself but a real cost to deployment velocity. |
| 3 | The RDS "Full configuration" console wizard **defaulted** to instance class `db.m7g.large` with Provisioned IOPS SSD (io2) storage at 400 GiB — dramatically different (and more expensive) than the intended `db.t3.micro` / gp2 / 20 GiB spec. Required manually locating the "Burstable classes" filter and correcting storage type/size. | RDS creation | A textbook illustration of manual-deployment drift risk: an unnoticed default could have provisioned a wildly oversized, costly instance with no warning. |

### 4.4 Terraform Run — Pre-flight & Errors (1 total)

Before applying, an AMI compatibility issue was found and fixed at **zero cloud cost**:

1. The originally specified AMI (Ubuntu 22.04 LTS "jammy") was no longer selectable as a plain SSD image in the AWS Console AMI browser at deployment time (only bundled variants such as "22.04 LTS with SQL Server 2022" remained). **Decision:** switch both environments to Ubuntu **24.04 LTS ("noble")** for a fair, consistent comparison.
2. After updating the Terraform AMI data-source filter, `terraform plan` immediately failed with `Error: Your query returned no results` — the 24.04-era Canonical AMIs are published under the `hvm-ssd-gp3` image path, not the `hvm-ssd` path used for 22.04. This was confirmed via `aws ec2 describe-images` and corrected in `terraform/modules/compute/main.tf`.
3. Re-running `terraform plan` succeeded cleanly: `Plan: 38 to add, 0 to change, 0 to destroy` — **no AWS resources were ever created with the incorrect configuration.**

**This is the central "auditability/consistency" advantage this experiment surfaced:** the Terraform error was caught deterministically by tooling, before any billable resource existed, at essentially zero cost. The equivalent manual error (RDS wrong instance class default, §4.3 #3) was only caught by a human visually reviewing a console screen — a fundamentally less reliable safety net.

### 4.5 Terraform Run — Detailed Timing

| Step | Result |
|---|---|
| `terraform validate` | `Success! The configuration is valid.` |
| `terraform plan` (1st attempt) | Failed at AMI data source — **0 resources touched** |
| AMI filter fix | Code change only, not a timed deployment step |
| `terraform plan` (2nd attempt) | `Plan: 38 to add, 0 to change, 0 to destroy` |
| `time terraform apply -auto-approve` | **`real 15m22.122s`** — `Apply complete! Resources: 38 added, 0 changed, 0 destroyed.` |
| — RDS Multi-AZ (long pole) | `Creation complete after 13m47s` |
| — Remaining resources (ALB, NAT GW, launch template, ASG, etc.) | ~1m35s combined |
| Verification | `/health` → `OK` (200); `/` → `{"status":"connected","tier":"app -> database","db_time":"2026-07-08T19:35:36.000Z","db_version":"8.0.46"}` (200) |
| Post-apply `terraform plan` (drift check) | **`No changes. Your infrastructure matches the configuration.`** |

Outputs captured: `alb_dns_name = "tf-alb-1052327157.eu-central-1.elb.amazonaws.com"`, `rds_endpoint` (marked `sensitive` in Terraform state).

## 5. Analysis

* **Deployment speed:** Terraform completed in 15m22s versus the manual run's ~116 minutes — a **~7.5× speedup**, almost entirely attributable to eliminating GUI navigation time and serializing independent steps (VPC, security groups, ALB, RDS, etc.) that Terraform's dependency graph parallelizes automatically where possible. Notably, **RDS Multi-AZ provisioning itself (13m47s) dominates the Terraform run** — meaning the *tooling overhead* Terraform eliminates is roughly 90+ minutes of the manual run's total, since the underlying AWS provisioning time for Multi-AZ RDS is a fixed cost neither approach can avoid.
* **Consistency / configuration drift:** the manual run accumulated 3 distinct configuration errors, each discovered only through manual visual inspection after the fact (in one case, after committing to an AWS account-tier upgrade). The Terraform run had exactly 1 configuration issue (an AMI path mismatch), caught deterministically by `terraform plan` with **zero resources ever created incorrectly**. This is a direct, empirical demonstration of the "configuration drift" risk described qualitatively in `docs/architecture.md` §3.2.
* **Auditability:** the Terraform run's history is fully captured in version-controlled `.tf` files plus the local state file — every resource, dependency, and applied change is inspectable and diffable. The manual run's audit trail exists only as this project's hand-maintained `note.md` journal (timings, decisions, screenshots) — functional, but entirely dependent on operator discipline rather than tooling guarantees.
* **Rollback complexity:** *(pending — see §7 Outlook / next steps; both environments' `terraform destroy` and manual teardown timings are to be captured and appended here once executed.)*

## 6. Verification Evidence

Both environments were verified through the identical two-endpoint check, proving the full `ALB → EC2 → RDS` chain end-to-end:

```
GET /health  → OK                                                          (HTTP 200)
GET /        → {"status":"connected","tier":"app -> database",
                "db_time": "<live RDS timestamp>", "db_version": "<MySQL version>"}   (HTTP 200)
```

Screenshot evidence checklist and capture status for both environments is tracked in `docs/manual-deployment-screenshots.md`.

## 7. Outlook

* **Rollback/teardown metric (not yet captured):** both `manual-*` and `tf-*` environments were left running after verification to allow screenshot capture; `terraform destroy` (timed) and the manual console teardown sequence still need to be executed and their durations added to §4.1/§5.
* **CI/CD integration:** a natural extension is wrapping the Terraform workflow in a CI pipeline (`terraform fmt -check`, `validate`, `plan` as a PR check, `apply` gated by approval) — turning this experiment's manual `terraform apply` step into a fully automated, auditable pipeline.
* **Cost analysis:** actual AWS spend for both simultaneous environments should be pulled from Cost Explorer after teardown and reconciled against the ~$2–5 estimate in `docs/plan.md` §7.
* **Scalability:** the architecture's `min/max/desired` ASG sizing (1/2/2) and single-NAT-GW design were deliberately minimal for a short-lived experiment; a production deployment would use one NAT Gateway per AZ and evaluate read replicas for RDS.
* **AMI pinning:** this run surfaced that "latest" AMI filters (`most_recent = true`) can silently break when a vendor changes their image-family naming convention (22.04 → 24.04's `hvm-ssd` → `hvm-ssd-gp3` path change). A more robust production pattern would pin to a specific, tested AMI ID or use SSM Parameter Store's `/aws/service/canonical/ubuntu/...` public parameters instead of a `data "aws_ami"` filter.

---

## Technical Handoff Summary

* **Infrastructure isolation:** manual resources (`manual-*`, CIDR `10.1.0.0/16`) and Terraform resources (`tf-*`, CIDR `10.0.0.0/16`) were deployed in parallel with no overlap, per the isolation convention in `docs/architecture.md` §8.
* **Full build journal:** every decision, timing entry, and error for both runs is preserved in `note.md` at the repository root — treat it as the primary source of truth for writing this report's remaining sections and the presentation deck.
* **Teardown protocols (pending execution):**
  * **Terraform:** `cd terraform && time terraform destroy -auto-approve` (timed for the rollback metric).
  * **Manual:** reverse-order console deletion — ASG → Launch Template → ALB/Target Group → RDS → DB Subnet Group → NAT Gateway → EIP → Route Tables → Security Groups → Internet Gateway → Subnets → VPC (full order in `docs/manual-deployment-screenshots.md`).

## References

* [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* [AWS VPC Networking Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
* [HashiCorp State Management Guide](https://developer.hashicorp.com/terraform/language/state)
* [Canonical Ubuntu Cloud Images (AMI naming conventions)](https://cloud-images.ubuntu.com/locator/ec2/)