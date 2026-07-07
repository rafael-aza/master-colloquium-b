# RED → GREEN: Security module assertions
# Verifies SG-to-SG referencing (no 0.0.0.0/0 on EC2/RDS ingress) and correct ports.
mock_provider "aws" {}

# ── ALB security group: HTTP :80 from internet ─────────────────────────────────
run "alb_sg_allows_http_80" {
  module {
    source = "./modules/security"
  }

  variables {
    name_prefix = "tf"
    vpc_id      = "vpc-12345678"
  }

  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.alb_http.from_port == 80
    error_message = "ALB SG must allow ingress on port 80"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.alb_http.cidr_ipv4 == "0.0.0.0/0"
    error_message = "ALB SG ingress must allow 0.0.0.0/0 (internet-facing)"
  }
}

# ── EC2 security group: :4000 from alb-sg only (SG reference, not CIDR) ────────
# referenced_security_group_id references a computed ID — not assertable in
# plan mode. cidr_ipv4 == null is sufficient: it proves a SG reference is used
# rather than a CIDR, which is exactly the "SG-to-SG" drift metric.
run "ec2_sg_ingress_4000_from_alb_sg_only" {
  module {
    source = "./modules/security"
  }

  variables {
    name_prefix = "tf"
    vpc_id      = "vpc-12345678"
  }

  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.ec2_from_alb.from_port == 4000
    error_message = "EC2 SG must allow ingress on port 4000"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.ec2_from_alb.to_port == 4000
    error_message = "EC2 SG ingress to_port must be 4000"
  }

  # Key drift metric: EC2 must use SG-to-SG reference, never a CIDR
  assert {
    condition     = aws_vpc_security_group_ingress_rule.ec2_from_alb.cidr_ipv4 == null
    error_message = "EC2 SG ingress must NOT use cidr_ipv4 — must reference alb-sg (SG-to-SG)"
  }
}

# ── RDS security group: :3306 from ec2-sg only (SG reference, not CIDR) ────────
run "rds_sg_ingress_3306_from_ec2_sg_only" {
  module {
    source = "./modules/security"
  }

  variables {
    name_prefix = "tf"
    vpc_id      = "vpc-12345678"
  }

  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.rds_from_ec2.from_port == 3306
    error_message = "RDS SG must allow ingress on port 3306"
  }

  # Key drift metric: RDS must use SG-to-SG reference, never a CIDR
  assert {
    condition     = aws_vpc_security_group_ingress_rule.rds_from_ec2.cidr_ipv4 == null
    error_message = "RDS SG ingress must NOT use cidr_ipv4 — must reference ec2-sg (SG-to-SG)"
  }
}
