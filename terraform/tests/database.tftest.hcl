# RED → GREEN: Database module assertions
mock_provider "aws" {}

run "rds_engine_and_class" {
  module {
    source = "./modules/database"
  }

  variables {
    name_prefix       = "tf"
    db_subnet_ids     = ["subnet-aaaa1111", "subnet-bbbb2222"]
    rds_sg_id         = "sg-rds-12345678"
    db_username       = "admin"
    db_password       = "TestPassword123!"
    db_instance_class = "db.t3.micro"
    db_engine_version = "8.0"
    db_multi_az       = true
  }

  command = plan

  assert {
    condition     = aws_db_instance.this.engine == "mysql"
    error_message = "RDS engine must be mysql"
  }

  assert {
    condition     = aws_db_instance.this.engine_version == "8.0"
    error_message = "RDS engine version must be 8.0"
  }

  assert {
    condition     = aws_db_instance.this.instance_class == "db.t3.micro"
    error_message = "RDS instance class must be db.t3.micro"
  }
}

run "rds_multi_az_and_private" {
  module {
    source = "./modules/database"
  }

  variables {
    name_prefix       = "tf"
    db_subnet_ids     = ["subnet-aaaa1111", "subnet-bbbb2222"]
    rds_sg_id         = "sg-rds-12345678"
    db_username       = "admin"
    db_password       = "TestPassword123!"
    db_instance_class = "db.t3.micro"
    db_engine_version = "8.0"
    db_multi_az       = true
  }

  command = plan

  assert {
    condition     = aws_db_instance.this.multi_az == true
    error_message = "RDS must be Multi-AZ"
  }

  assert {
    condition     = aws_db_instance.this.publicly_accessible == false
    error_message = "RDS must NOT be publicly accessible"
  }

  assert {
    condition     = aws_db_instance.this.port == 3306
    error_message = "RDS port must be 3306"
  }
}

run "rds_subnet_group_covers_both_subnets" {
  module {
    source = "./modules/database"
  }

  variables {
    name_prefix       = "tf"
    db_subnet_ids     = ["subnet-aaaa1111", "subnet-bbbb2222"]
    rds_sg_id         = "sg-rds-12345678"
    db_password       = "TestPassword123!"
    db_instance_class = "db.t3.micro"
    db_engine_version = "8.0"
    db_multi_az       = true
  }

  command = plan

  assert {
    condition     = length(aws_db_subnet_group.this.subnet_ids) == 2
    error_message = "DB subnet group must include exactly 2 subnets (one per AZ)"
  }
}
