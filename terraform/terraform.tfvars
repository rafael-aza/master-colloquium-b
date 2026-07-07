aws_region        = "eu-central-1"
vpc_cidr          = "10.0.0.0/16"
az_a              = "eu-central-1a"
az_b              = "eu-central-1b"
name_prefix       = "tf"
instance_type     = "t3.micro"
db_instance_class = "db.t3.micro"
db_engine_version = "8.0"
db_multi_az       = true
db_username       = "admin"
app_repo_url      = "https://github.com/rafael-aza/master-colloquium-b.git"
min_size          = 1
max_size          = 2
desired_capacity  = 2
# db_password must be supplied at runtime:
#   export TF_VAR_db_password="<your-password>"
#   or terraform apply -var="db_password=<your-password>"
