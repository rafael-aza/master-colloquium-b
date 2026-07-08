# Deployment Journal — Manual (Click-Ops) Run

**Project:** Master Colloquium B — IaC vs Manual AWS Provisioning
**Environment:** Manual / Click-Ops (AWS Management Console)
**Region:** `eu-central-1` (Frankfurt)
**VPC CIDR:** `10.1.0.0/16` (isolated from Terraform's `10.0.0.0/16`)
**Naming prefix:** `manual-`
**Date started:** 2026-07-08

> Timing is tracked by the user's own stopwatch (elapsed time since the start of the run), reported after each step and logged here. AWS credentials used: root account (flagged as anti-pattern in `architecture.md` discussion, accepted for this experiment). Account confirmed clean slate before starting (0 VPC/EC2/RDS/NAT/EIP in `eu-central-1`).

---

## Decisions Log

| # | Decision | Rationale |
|---|---|---|
| 1 | Do manual deployment first, Terraform run second | Per `docs/plan.md` Day 2 schedule |
| 2 | Manual VPC CIDR = `10.1.0.0/16` | Isolation from Terraform's `10.0.0.0/16`, per `architecture.md` §8 naming/isolation convention |
| 3 | Timing tracked via user's own stopwatch (elapsed time), not wall-clock timestamps | Assistant has no live clock access; user reports elapsed time at each milestone |
| 4 | All manual resources use `manual-` prefix | Per naming convention in `architecture.md` §8, keeps environments isolated for billing/cleanup || 6 | Reordered steps: create DB Subnet Group + RDS instance (originally step 10-11) BEFORE the Launch Template (step 8) | User-data script needs the RDS endpoint at boot time; RDS also takes 10-15 min to provision, so starting it early lets it provision in the background while we build the launch template + ASG in parallel. Matches how Terraform's compute module actually depends on database module's `rds_endpoint` output. |
| 7 | Switched base AMI from Ubuntu 22.04 LTS (specified in `architecture.md` / Terraform AMI filter) to **Ubuntu 24.04 LTS (HVM), SSD Volume Type** for BOTH the manual and the upcoming Terraform run | The plain Ubuntu 22.04 LTS SSD AMI listing was no longer available/searchable in the AMI browser at deployment time (only bundled variants like "22.04 LTS with SQL Server 2022" were showing). 24.04 uses the same `apt-get`/`curl`/`systemd` bootstrap approach, so the user-data script is unaffected. **TODO before Terraform run:** update `terraform/modules/compute/main.tf` AMI filter from `ubuntu-jammy-22.04` to `ubuntu-noble-24.04` to keep both environments consistent. || 5 | Instance specs, ALB/target group config, RDS config, and user-data script mirrored exactly from Terraform modules (`terraform/modules/compute`, `terraform/modules/database`) | Ensures fair apples-to-apples comparison between manual and IaC deployments |

---

## Timing Log

| Step | Description | Elapsed Time | Notes |
|---|---|---|---|
| T0 | Start — clicked "Create VPC" | 00:00 | Official start of manual run stopwatch |
| 1 | VPC created (`manual-vpc`, `10.1.0.0/16`) | 03:40 | |
| 2 | 6 subnets created + auto-assign public IP enabled on public-a/b | 09:18 | Step duration: 5m38s |
| 3 | Internet Gateway created (`manual-igw`) + attached to `manual-vpc` | 11:38 | Step duration: 2m20s |
| 4 | Elastic IP allocated + NAT Gateway created (`manual-natgw`) in `manual-public-a` | 13:44 | Step duration: 2m06s (creation clicked; provisioning to `Available` continues in background) |
| 5 | Route tables created (`manual-rt-public` → IGW, `manual-rt-private` → NAT GW) + subnet associations | 24:04 | Step duration: 10m20s (includes 1 error + fix, see Errors log) |
| 6 | 3 Security Groups created (`manual-alb-sg`, `manual-ec2-sg`, `manual-rds-sg`) with SG-to-SG chained inbound rules | 28:54 | Step duration: 4m50s |
| 7 | Target group (`manual-tg`, HTTP:4000, health check `/health`) + ALB (`manual-alb`, internet-facing, HTTP:80 listener → forward to `manual-tg`) created | 39:54 | Step duration: 11m00s |
| — | **STOPWATCH RESET** during account-upgrade / billing detour (free plan → paid plan upgrade required for Multi-AZ RDS) | reset to 00:00 | Cumulative total carries forward: 39:54 (pre-reset) + time since reset |
| 8a/8b | DB Subnet Group (`manual-db-subnet-group`) + RDS instance (`manual-rds`, MySQL 8.0, `db.t3.micro`, gp2 20GiB, Multi-AZ 2-instance, `manual-rds-sg`, port 3306) creation submitted. Includes: account upgrade to paid plan (needed — Multi-AZ RDS not available on Free Plan), fixing instance class from wrong default (`db.m7g.large`/io2/400GiB) to correct spec, unchecking auto-generate password. | ~30:00 since reset → **cumulative ≈ 69:54** | Step duration since reset: ~30m00s. RDS provisioning continues in background (10-15 min to `Available`), not blocking next steps. |
| 9 | Launch Template (`manual-lt`) created: Ubuntu 24.04 LTS AMI, `t3.micro`, key pair, `manual-ec2-sg`, full user-data script with real RDS endpoint (`manual-rds.c5ys4c82m65z.eu-central-1.rds.amazonaws.com`), `admin` user, `mysql` schema, real app repo URL, user-supplied DB password | +30:00 since previous → **cumulative ≈ 99:54** | RDS confirmed `Available` before this step; endpoint verified via `aws rds describe-db-instances`. Included time spent locating "Advanced details"/User data field and resolving AMI selection (22.04 unavailable, chose 24.04, see Decisions #7). |
| 10 | Auto Scaling Group (`manual-asg`) created: launch template `manual-lt` (Latest), subnets `manual-app-a`/`manual-app-b`, attached to `manual-tg`, ELB health checks on, desired 2 / min 1 / max 2, no scaling policies | +10:00 since previous → **cumulative ≈ 109:54** | Status "Updating capacity" immediately after creation — instances launching now |
| 11 | **VERIFICATION SUCCESS** — both instances `InService`/`HEALTHY` (ASG level) and `healthy` (ALB target group level, port 4000). `curl http://manual-alb-570599602.eu-central-1.elb.amazonaws.com/health` → `OK` (HTTP 200). `curl http://manual-alb-570599602.eu-central-1.elb.amazonaws.com/` → `{"status":"connected","tier":"app -> database","db_time":"2026-07-08T18:13:49.000Z","db_version":"8.4.9"}` (HTTP 200). Full chain ALB → EC2 → RDS confirmed working end to end. | **ESTIMATED ≈ 116:00** (user did not capture exact stopwatch reading at this milestone; estimate = 109:54 + ~6 min typical instance boot + user-data script + 2x health-check interval) | **MANUAL DEPLOYMENT RUN COMPLETE.** Estimated total elapsed: **~1h 56m (116 min)**, including 3 logged errors/detours (route table mixup, free-plan billing block, RDS instance-class default mismatch). This figure should be noted as an approximation in the report — flag the stopwatch gap as a methodology caveat. |

---

## Progress Log (Step-by-Step)

- [x] **Step 1 — VPC**: `manual-vpc`, CIDR `10.1.0.0/16` — done at 03:40
- [x] **Step 2 — 6 Subnets**: `manual-public-a/b`, `manual-app-a/b`, `manual-db-a/b` + enable auto-assign public IPv4 on the two public subnets — done at 09:18
- [x] **Step 3 — Internet Gateway**: create + attach to `manual-vpc` — done at 11:38
- [x] **Step 4 — NAT Gateway**: allocate EIP, create NAT GW in `manual-public-a` — create clicked at 13:44 (provisioning in background, verify `Available` before relying on it)
- [x] **Step 5 — Route Tables**: public RT (→ IGW) + private RT (→ NAT GW), associate all 6 subnets — done at 24:04 (1 error/fix)
- [x] **Step 6 — Security Groups**: `manual-alb-sg`, `manual-ec2-sg`, `manual-rds-sg` with SG-to-SG chained rules — done at 28:54
- [x] **Step 7 — ALB**: internet-facing, listener HTTP :80, target group HTTP :4000 (health check `/health`, matcher 200) — done at 39:54
- [x] **Step 8 (reordered) — DB Subnet Group + RDS Instance**: `manual-db-subnet-group`, `manual-rds` (MySQL 8.0, db.t3.micro, Multi-AZ, gp2 20GiB) — creation submitted at cumulative ~69:54; confirmed `Available` before Step 9
- [x] **Step 9 — Launch Template**: `manual-lt`, Ubuntu 24.04 LTS AMI, `t3.micro`, `manual-ec2-sg`, user-data script (Node 18 + git, clone app repo, systemd `demoapp` service on :4000) with real RDS endpoint — done at cumulative ~99:54
- [x] **Step 10 — Auto Scaling Group**: `manual-asg`, min 1 / max 2 / desired 2, attached to `manual-tg`, private app subnets — created at cumulative ~109:54, instances launching
- [x] **Step 11 — Verification**: both instances healthy, `/health` → 200 OK, `/` → 200 with live DB time from `manual-rds` — **DONE, estimated cumulative ~116:00**

## 🏁 MANUAL DEPLOYMENT RUN: COMPLETE

**Estimated total elapsed time: ~116 minutes (1h 56m)** (see caveat in timing log — final milestone time was estimated, not directly measured)
**Total errors/detours logged: 3** (route table IGW/NAT mixup, AWS Free Plan billing block requiring account upgrade, RDS wizard wrong default instance class/storage)

**Next actions:**
1. ~~Capture screenshots of AWS console~~ → deferred to later; checklist documented in `docs/manual-deployment-screenshots.md`
2. Record this data in `docs/report.md` §5–6 (Implementation / Results) — deferred to report-writing phase
3. **IMPORTANT — cost control:** `manual-*` resources are still LIVE and billing (Multi-AZ RDS + NAT Gateway + ALB). Teardown deferred until after screenshots are captured (see `docs/manual-deployment-screenshots.md` for teardown order) — must not forget this.
4. **NOW IN PROGRESS:** Terraform deployment run for comparison — see section below.

---

## Terraform Deployment Run — Journal

*(Manual `manual-*` resources remain live in the background during this run — both environments are isolated by CIDR/prefix, so no conflict. Cost clock is running on both simultaneously; teardown both when done.)*

### Pre-flight fixes needed
- [ ] Update `terraform/modules/compute/main.tf` AMI filter from `ubuntu-jammy-22.04` → `ubuntu-noble-24.04` (22.04 plain AMI unavailable in console; must match manual run's OS for fair comparison)
- [ ] Set `TF_VAR_db_password` environment variable before `terraform apply`
- [ ] Re-run `terraform validate` after AMI filter change

- [ ] **Step 9 — Auto Scaling Group**: min 1 / max 2 / desired 2, attached to target group, private app subnets
- [ ] **Step 10 — DB Subnet Group**: covering `manual-db-a` + `manual-db-b`
- [ ] **Step 11 — RDS Instance**: MySQL 8.0, `db.t3.micro`, Multi-AZ, 20GB gp2, port 3306
- [ ] **Step 12 — Verification**: `curl http://<alb-dns>/health` → 200, `curl http://<alb-dns>/` → DB time via `SELECT NOW()`

---

## Errors / Rework Log (for drift/consistency metric)

| # | Issue | Step | Impact |
|---|---|---|---|
| 1 | Private route table's `0.0.0.0/0` route was mistakenly created pointing to the Internet Gateway instead of the NAT Gateway. Had to delete/recreate the route (some sources say the route was recreated) targeting `manual-natgw` correctly. | Step 5 — Route Tables | Added rework time within the 10m20s step duration; classic manual-deployment misconfiguration matching the "most commonly missed" pattern noted in `architecture.md` §3.2 |
| 2 | AWS account was on the restrictive "Free Plan", which blocked Multi-AZ RDS creation and required an account upgrade to a standard paid plan (backed by existing $138.77 promo credits) before continuing. | Step 8b — RDS creation | Real-world manual-deployment friction not present in the Terraform run; unplanned detour, stopwatch reset here. Worth noting in report as an account-tier gotcha specific to newer/free-tier AWS accounts. |
| 3 | RDS "Full configuration" wizard defaulted to `db.m7g.large` instance class with Provisioned IOPS SSD (io2) storage type at 400 GiB — wildly different (and more expensive) than our `db.t3.micro` / gp2 / 20GiB spec. Had to manually switch instance class filter to "Burstable classes" and pick `db.t3.micro`, then change storage type to gp2 and allocated storage to 20 GiB. | Step 8b — RDS creation | Another example of manual-deployment drift risk: easy to accidentally provision an oversized/expensive instance if defaults aren't checked carefully. |

---

## Resource ID Reference

| Resource | ID / Name | Notes |
|---|---|---|
| VPC | `manual-vpc` | ID: *(pending — paste from console)* |
| Subnet: manual-public-a | | |
| Subnet: manual-public-b | | |
| Subnet: manual-app-a | | |
| Subnet: manual-app-b | | |
| Subnet: manual-db-a | | |
| Subnet: manual-db-b | | |
| Internet Gateway | | |
| Elastic IP | | |
| NAT Gateway | | |
| Route Table (public) | | |
| Route Table (private) | | |
| Security Group: manual-alb-sg | | |
| Security Group: manual-ec2-sg | | |
| Security Group: manual-rds-sg | | |
| ALB | | |
| Target Group | | |
| Launch Template | | |
| Auto Scaling Group | | |
| DB Subnet Group | | |
| RDS Instance | | |

---

*This file is updated live as we progress through the manual deployment. Final totals (elapsed time, error count) will be transferred into `docs/report.md` §5–6 once the run is complete.*

---
---

# Deployment Journal — Terraform (IaC) Run

**Environment:** Terraform (`terraform apply`)
**Region:** `eu-central-1` (Frankfurt)
**VPC CIDR:** `10.0.0.0/16` (isolated from manual's `10.1.0.0/16`)
**Naming prefix:** `tf`
**Date started:** 2026-07-08 (same day as manual run)

## Pre-flight / Decisions Log

| # | Decision | Rationale |
|---|---|---|
| 1 | Kept manual run's AMI decision (Ubuntu 24.04 LTS "noble") for Terraform too, updating `terraform/modules/compute/main.tf`'s `data.aws_ami.ubuntu` filter from `ubuntu-jammy-22.04` to `ubuntu-noble-24.04` | Fair comparison — same OS/AMI family across both environments (see manual run Decision #7) |
| 2 | `terraform validate` run first — passed cleanly | Sanity check before touching any cloud resources |
| 3 | `terraform plan` run before `apply`, with `TF_VAR_db_password` exported for the session | Standard safe IaC workflow; also intentionally used as a live demonstration of Terraform's safety net for the report |
| 4 | **Bug found by `terraform plan` (zero resources touched):** AMI data source `module.compute.data.aws_ami.ubuntu` returned "Your query returned no results" — the filter path `ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*` doesn't exist; 24.04-era Canonical AMIs are published under `hvm-ssd-gp3`, not `hvm-ssd` (that was the 22.04-era path). Confirmed via `aws ec2 describe-images` and fixed the filter. | **Key report evidence:** this is exactly the kind of error `terraform plan`/`validate` catches *before* any billable resource is created — contrast with the manual run, where a similar wrong-default mistake (RDS instance class) was only caught by manually reviewing the wizard screen, and would have gone live if unnoticed. |
| 5 | Re-ran `terraform plan` after the AMI fix → succeeded: **`Plan: 38 to add, 0 to change, 0 to destroy`** | Confirms fix works; ready for `terraform apply` |

## Timing Log

| Step | Description | Elapsed Time | Notes |
|---|---|---|---|
| T0 | `terraform validate` | — | Passed: "Success! The configuration is valid." |
| T1 | `terraform plan` (1st attempt) | — | Failed at AMI data source — 0 resources created/touched (plan-only, no apply) |
| T2 | AMI filter fixed (`hvm-ssd` → `hvm-ssd-gp3`) | — | Code fix, not a timed deployment step |
| T3 | `terraform plan` (2nd attempt) | — | **Succeeded**: `Plan: 38 to add, 0 to change, 0 to destroy` |
| T4 | `terraform apply -auto-approve` | **15m 22.122s (real)** | Exact wall-clock time via `time terraform apply`. `Apply complete! Resources: 38 added, 0 changed, 0 destroyed.` RDS Multi-AZ was the long pole: `module.database.aws_db_instance.this: Creation complete after 13m47s`. ALB, NAT GW, launch template, and ASG all created in parallel/sequence within the remaining ~1m35s. Outputs: `alb_dns_name = "tf-alb-1052327157.eu-central-1.elb.amazonaws.com"`, `rds_endpoint` (sensitive). |

## Errors / Rework Log (for drift/consistency metric)

| # | Issue | Step | Impact |
|---|---|---|---|
| 1 | AMI filter path outdated (`hvm-ssd` → `hvm-ssd-gp3` for 24.04/noble) | `terraform plan` (pre-apply) | **Zero cost/rollback impact** — caught entirely at plan-time, no cloud resources were ever created with the bad config. This is the central "auditability/consistency" advantage Terraform has over manual console work, and is worth highlighting explicitly in `docs/report.md` §6. |

## Verification & Drift Check Results

| Check | Result |
|---|---|
| `curl http://tf-alb-1052327157.eu-central-1.elb.amazonaws.com/health` | `OK` — **HTTP 200** |
| `curl http://tf-alb-1052327157.eu-central-1.elb.amazonaws.com/` | `{"status":"connected","tier":"app -> database","db_time":"2026-07-08T19:35:36.000Z","db_version":"8.0.46"}` — **HTTP 200** |
| `terraform plan` (post-apply, drift check) | **"No changes. Your infrastructure matches the configuration."** ✅ |

Full chain `ALB → EC2 → RDS` confirmed working, and the drift-verification criterion from `architecture.md` §6.2 step 5 is satisfied exactly.

## Resource ID Reference (Terraform — populated after apply)

| Resource | ID / Name | Notes |
|---|---|---|
| VPC | `tf-vpc` | 38 resources total created |
| ALB DNS name | `tf-alb-1052327157.eu-central-1.elb.amazonaws.com` | via `terraform output alb_dns_name` |
| RDS endpoint | *(sensitive, retrievable via `terraform output rds_endpoint`)* | Multi-AZ MySQL 8.0, `db.t3.micro` |

## 🏁 HEADLINE RESULT

| Environment | Total Deployment Time | Errors/Detours |
|---|---|---|
| **Manual (Click-Ops)** | ~116 min (1h 56m, estimated) | 3 |
| **Terraform (IaC)** | **15m 22s** (exact) | 1 (caught entirely at `plan`-time, zero cloud impact) |

**Terraform was ~7.5x faster** in this run, and its one error was caught safely before touching any real infrastructure — versus manual errors that were only caught by visually inspecting console screens after the fact (and in one case, after upgrading the AWS account plan to even proceed).

---

*Next: verify ALB → HTTP 200 on `/health` and `/`, then `terraform plan` again to confirm "No changes" (drift check), per `docs/architecture.md` §6.2.* ✅ **Done — see Verification & Drift Check Results above.**

---
---

# 📋 Overall Wrap-Up & Handoff (2026-07-08, end of session)

## What's done

- ✅ Manual 3-tier deployment: built, verified end-to-end, ~116 min (estimated), 3 errors logged
- ✅ Terraform 3-tier deployment: built, verified end-to-end, **15m22.122s exact**, 1 pre-apply error (zero cloud impact), drift check passed
- ✅ All project docs updated to reflect real results: `docs/report.md` (full rewrite of §1–§7 with real data), `docs/plan.md` (status tables + checkboxes), `docs/architecture.md` (AMI deviation note), `README.md` (prereqs + results summary)
- ✅ `docs/manual-deployment-screenshots.md` expanded into a combined Manual + Terraform evidence checklist (Part A / Part B), including CLI backup commands and a teardown runbook for both environments

## What's NOT done yet (pick up here next session)

1. **Screenshot capture** — neither environment has had screenshots taken yet. Checklist ready in `docs/manual-deployment-screenshots.md` (Part A for manual, Part B for Terraform). Do this **before** teardown.
2. **Teardown of both environments** — `manual-*` (CIDR `10.1.0.0/16`) and `tf-*` (CIDR `10.0.0.0/16`) are **BOTH STILL LIVE** in `eu-central-1` as of this note. This includes 2× Multi-AZ RDS, 2× NAT Gateway, 2× ALB — all billing hourly. **Do not forget this** — cost guardrail from `docs/plan.md` §7 says same-day teardown.
   - Terraform: `cd terraform; export TF_VAR_db_password="Password247"; time terraform destroy -auto-approve` (time it — this is the rollback metric, still missing from the report)
   - Manual: reverse-order console deletion, full sequence in `docs/manual-deployment-screenshots.md` bottom section
3. **Rollback/teardown timing** — once both teardowns are done, add the timings into `docs/report.md` §5 (currently marked "pending" there) and the headline table in §4.1
4. **Cost reconciliation** — after teardown, check AWS Billing → Credits page again, compare actual $ used against the ~$2-5 estimate, note in `docs/report.md` §7
5. **Presentation deck** — not started at all (sections 1-4 + 7 per Prof. Purat's guidance, per `docs/plan.md`)
6. **Project definition form** — required for Moodle, not started

## Key facts/values to remember

| Item | Value |
|---|---|
| Manual DB password | *(only user knows — was entered directly in AWS console, not shared with assistant)* |
| Terraform DB password | `Password247` (set via `TF_VAR_db_password`, needed again for `terraform destroy`) |
| Manual ALB DNS | `manual-alb-570599602.eu-central-1.elb.amazonaws.com` |
| Terraform ALB DNS | `tf-alb-1052327157.eu-central-1.elb.amazonaws.com` |
| Manual RDS endpoint | `manual-rds.c5ys4c82m65z.eu-central-1.rds.amazonaws.com:3306` |
| AWS Account | `301003368146`, root credentials, region `eu-central-1`, upgraded from Free Plan to paid (backed by ~$138 promo credits) |
| Base AMI (both envs) | Ubuntu 24.04 LTS "noble", `hvm-ssd-gp3` image path (NOT `hvm-ssd` — that's 22.04-era) |

## Files touched this session

- `note.md` (this file) — full build journal for both runs
- `docs/report.md` — full rewrite with real results
- `docs/plan.md` — status tables and checkboxes updated
- `docs/architecture.md` — AMI deviation note added
- `README.md` — prereqs + results summary added
- `docs/manual-deployment-screenshots.md` — expanded to cover both environments
- `terraform/modules/compute/main.tf` — AMI filter fixed (`ubuntu-jammy-22.04` → `ubuntu-noble-24.04`, `hvm-ssd` → `hvm-ssd-gp3`)
