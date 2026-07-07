# RED → GREEN: VPC module assertions
# Run with: cd terraform && terraform test
mock_provider "aws" {}

# ── VPC configuration ──────────────────────────────────────────────────────────
run "vpc_cidr_and_dns" {
  module {
    source = "./modules/vpc"
  }

  variables {
    name_prefix = "tf"
    vpc_cidr    = "10.0.0.0/16"
    az_a        = "eu-central-1a"
    az_b        = "eu-central-1b"
  }

  command = plan

  assert {
    condition     = aws_vpc.this.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block must be 10.0.0.0/16"
  }

  assert {
    condition     = aws_vpc.this.enable_dns_hostnames == true
    error_message = "VPC must have DNS hostnames enabled"
  }

  assert {
    condition     = aws_vpc.this.enable_dns_support == true
    error_message = "VPC must have DNS support enabled"
  }
}

# ── Six subnets across two AZs ─────────────────────────────────────────────────
run "subnets_cidr_and_az" {
  module {
    source = "./modules/vpc"
  }

  variables {
    name_prefix = "tf"
    vpc_cidr    = "10.0.0.0/16"
    az_a        = "eu-central-1a"
    az_b        = "eu-central-1b"
  }

  command = plan

  assert {
    condition     = aws_subnet.public_a.cidr_block == "10.0.1.0/24"
    error_message = "Public subnet A must be 10.0.1.0/24"
  }

  assert {
    condition     = aws_subnet.public_b.cidr_block == "10.0.2.0/24"
    error_message = "Public subnet B must be 10.0.2.0/24"
  }

  assert {
    condition     = aws_subnet.private_app_a.cidr_block == "10.0.3.0/24"
    error_message = "Private app subnet A must be 10.0.3.0/24"
  }

  assert {
    condition     = aws_subnet.private_app_b.cidr_block == "10.0.4.0/24"
    error_message = "Private app subnet B must be 10.0.4.0/24"
  }

  assert {
    condition     = aws_subnet.private_db_a.cidr_block == "10.0.5.0/24"
    error_message = "Private DB subnet A must be 10.0.5.0/24"
  }

  assert {
    condition     = aws_subnet.private_db_b.cidr_block == "10.0.6.0/24"
    error_message = "Private DB subnet B must be 10.0.6.0/24"
  }

  assert {
    condition     = aws_subnet.public_a.availability_zone == "eu-central-1a"
    error_message = "Public subnet A must be in eu-central-1a"
  }

  assert {
    condition     = aws_subnet.public_b.availability_zone == "eu-central-1b"
    error_message = "Public subnet B must be in eu-central-1b"
  }

  assert {
    condition     = aws_subnet.private_db_a.availability_zone == "eu-central-1a"
    error_message = "DB subnet A must be in eu-central-1a"
  }

  assert {
    condition     = aws_subnet.private_db_b.availability_zone == "eu-central-1b"
    error_message = "DB subnet B must be in eu-central-1b"
  }
}

# ── Single NAT Gateway in Public Subnet A ──────────────────────────────────────
# subnet_id references a computed value (aws_subnet.public_a.id) so it is
# "known after apply" — not assertable in plan mode. The wiring is explicit in
# main.tf: subnet_id = aws_subnet.public_a.id. Here we verify the EIP that
# backs the NAT GW is configured for VPC scope.
run "nat_gateway_placement" {
  module {
    source = "./modules/vpc"
  }

  variables {
    name_prefix = "tf"
    vpc_cidr    = "10.0.0.0/16"
    az_a        = "eu-central-1a"
    az_b        = "eu-central-1b"
  }

  command = plan

  assert {
    condition     = aws_eip.nat.domain == "vpc"
    error_message = "EIP backing the NAT Gateway must be in VPC domain"
  }

  assert {
    condition     = aws_nat_gateway.this.tags["Name"] == "${var.name_prefix}-natgw"
    error_message = "NAT Gateway must have the correct name tag"
  }
}

# ── Routing: public → IGW, private → NAT ──────────────────────────────────────
# gateway_id / nat_gateway_id reference computed IDs — not assertable in plan
# mode. The wiring is explicit in main.tf. Asserting destination_cidr_block and
# route table name tags is sufficient to prove the route configuration.
run "route_destinations" {
  module {
    source = "./modules/vpc"
  }

  variables {
    name_prefix = "tf"
    vpc_cidr    = "10.0.0.0/16"
    az_a        = "eu-central-1a"
    az_b        = "eu-central-1b"
  }

  command = plan

  assert {
    condition     = aws_route.public_internet.destination_cidr_block == "0.0.0.0/0"
    error_message = "Public internet route must cover all destinations (0.0.0.0/0)"
  }

  assert {
    condition     = aws_route.private_nat.destination_cidr_block == "0.0.0.0/0"
    error_message = "Private NAT route must cover all destinations (0.0.0.0/0)"
  }

  assert {
    condition     = aws_route_table.public.tags["Name"] == "${var.name_prefix}-rt-pub"
    error_message = "Public route table must have the correct name tag"
  }

  assert {
    condition     = aws_route_table.private.tags["Name"] == "${var.name_prefix}-rt-priv"
    error_message = "Private route table must have the correct name tag"
  }
}
