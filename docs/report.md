# Project Report: Comparative Analysis of Cloud Infrastructure Provisioning

**Date:** July 7, 2026

**Project Scope:** Master Colloquium B

**Supervisor:** Prof. Dr.-Ing. Marcus Purat

---

## 1. Introduction

Modern cloud environments require scalable, reliable, and repeatable infrastructure deployment strategies. This project investigates the transition from traditional manual provisioning ("Click-Ops") to automated Infrastructure as Code (IaC) methodologies. The primary research question is: *To what extent does IaC (Terraform) improve deployment speed and operational consistency compared to manual AWS Management Console provisioning?*

## 2. Technical Architecture & Environment

The deployment environment was established using WSL2 Ubuntu, with the `eu-central-1` (Frankfurt) region as the target for both manual and automated comparative runs.

* **IaC Tool:** Terraform `v1.15.6`
* **Cloud Provider:** Amazon Web Services (AWS)
* **Instance Specification:** `t3.micro` (maintained for 1:1 hardware parity)
* **Resource Scope:** VPC, Public Subnet, Internet Gateway, Route Table, Security Group, and EC2 Instance.

## 3. Methodology: Comparative Analysis

A dual-approach workflow was utilized to gather baseline data. Manual provisioning was timed from the initiation of the VPC creation through the final EC2 launch. Terraform provisioning was measured from the initialization command (`terraform init`) through successful resource application (`terraform apply`).

### Performance Metrics Table

| Metric | Manual (AWS Console) | Automated (Terraform) |
| --- | --- | --- |
| **Deployment Time** | 01:17:40 | 00:20:00 |
| **Operational Process** | Manual (Click-Ops) | Declarative (IaC) |
| **Reliability** | Susceptible to human error | High (Idempotent) |
| **Configuration Audit** | Manual logging | State-file management |

### Comparative Performance Graph

*(Note: A bar chart detailing the Performance Score out of 10 for Deployment Time, Consistency, Auditability, and Reliability. Terraform scores consistently higher across all metrics except total time elapsed, reflecting the data in the table above.)*

## 4. Analysis of Execution

* **Manual Provisioning:** The 01:17:40 duration highlights the administrative complexity of GUI navigation. Each manual step—such as subnet association and routing configuration—introduces potential for "configuration drift," where human error leads to environments that are not functionally identical.
* **Terraform Provisioning:** The 00:20:00 duration demonstrates the efficiency of a declarative model. By defining infrastructure as version-controlled code, the provisioning process is not only accelerated but rendered repeatable, ensuring the environment is identical across every deployment.

## 5. Conclusion

The comparative analysis confirms that IaC offers a decisive advantage in deployment velocity and operational reliability. By removing the manual burden of the AWS Console, the infrastructure is transformed into an auditable, version-controlled asset. These findings underscore the necessity of automation for professional DevOps workflows and complex academic cloud research.

---

## Technical Handoff Summary

* **Infrastructure Isolation:** Manual resources (`manual-*`) and automated resources (`tf-*`) were deployed in parallel using distinct CIDR blocks to maintain rigorous comparative isolation.
* **Teardown Protocols:**
* **Automated:** Execute `terraform destroy -auto-approve` from the project root.
* **Manual:** Terminate EC2 instances and delete VPC-associated resources via the AWS console to ensure compliance with billing and resource lifecycle policies.



## References

* [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* [AWS VPC Networking Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
* [HashiCorp State Management Guide](https://developer.hashicorp.com/terraform/language/state)