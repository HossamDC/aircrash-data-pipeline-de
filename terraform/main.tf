terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# If you set AWS_PROFILE environment variable, Terraform will pick it up automatically.
provider "aws" {
  region  = var.aws_region
  profile = length(var.aws_profile) > 0 ? var.aws_profile : null
}

# ---------------------------------------------
# S3 BUCKET
# ---------------------------------------------
resource "aws_s3_bucket" "data_bucket" {
  bucket = var.bucket_name
  tags = {
    Name        = "Spark Data Bucket"
    Environment = "Dev"
  }
}

# ---------------------------------------------
# REDSHIFT IAM ROLES
# ---------------------------------------------
resource "aws_iam_role" "redshift_s3" {
  name = "RedshiftS3AccessRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow",
                   Principal = { Service = "redshift.amazonaws.com" },
                   Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "redshift_s3_readonly" {
  role       = aws_iam_role.redshift_s3.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role" "redshift_spectrum" {
  name = "RedshiftSpectrumRole"
  assume_role_policy = aws_iam_role.redshift_s3.assume_role_policy
}

resource "aws_iam_role_policy_attachment" "spectrum_s3" {
  role       = aws_iam_role.redshift_spectrum.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "spectrum_glue" {
  role       = aws_iam_role.redshift_spectrum.name
  policy_arn = "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess"
}

# ---------------------------------------------
# REDSHIFT SUBNET GROUP & SECURITY GROUP
# ---------------------------------------------
resource "aws_redshift_subnet_group" "this" {
  name       = "demo-subnet-group"
  subnet_ids = var.subnet_ids
  tags = { Name = "Demo Subnet Group" }
}

resource "aws_security_group" "redshift" {
  name   = "redshift-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "Redshift SG" }
}

# ---------------------------------------------
# REDSHIFT CLUSTER
# ---------------------------------------------
resource "aws_redshift_cluster" "this" {
  cluster_identifier      = "demo-cluster"
  database_name           = var.bucket_name  # or separate var
  master_username         = var.master_username
  master_password         = var.master_password
  node_type               = var.cluster_node_type
  cluster_type            = var.cluster_type
  skip_final_snapshot     = true

  iam_roles = [
    aws_iam_role.redshift_s3.arn,
    aws_iam_role.redshift_spectrum.arn
  ]

  cluster_subnet_group_name = aws_redshift_subnet_group.this.name
  vpc_security_group_ids    = var.vpc_security_group_ids

  tags = {
    Name        = "Demo Cluster"
    Environment = "Dev"
  }
}

# ---------------------------------------------
# EMR IAM ROLES & INSTANCE PROFILE
# ---------------------------------------------
resource "aws_iam_role" "emr_service" {
  name               = "EMR_DefaultRole"
  assume_role_policy = file("emr-service-trust-policy.json")
  tags = { "for-use-with-amazon-emr-managed-policies" = "true" }
}

resource "aws_iam_policy_attachment" "emr_service_attach" {
  name       = "emr_service_policy"
  roles      = [ aws_iam_role.emr_service.name ]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEMRServicePolicy_v2"
}

resource "aws_iam_role" "emr_ec2" {
  name               = "EMR_EC2_DefaultRole"
  assume_role_policy = file("emr-trust-policy.json")
  tags = { "for-use-with-amazon-emr-managed-policies" = "true" }
}

resource "aws_iam_policy_attachment" "emr_ec2_attach" {
  name       = "emr_ec2_policy"
  roles      = [ aws_iam_role.emr_ec2.name ]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

resource "aws_iam_instance_profile" "emr_profile" {
  name = "EMR_EC2_InstanceProfile"
  role = aws_iam_role.emr_ec2.name
}

# ---------------------------------------------
# EMR CLUSTER
# ---------------------------------------------
resource "aws_emr_cluster" "this" {
  name          = "MyEMRCluster"
  release_label = "emr-6.10.0"
  applications  = ["Spark"]

  service_role                   = aws_iam_role.emr_service.arn
  ec2_attributes {
    key_name                          = var.key_name
    subnet_id                         = var.subnet_ids[0]
    emr_managed_master_security_group = var.vpc_security_group_ids[0]
    emr_managed_slave_security_group  = var.vpc_security_group_ids[0]
    instance_profile                  = aws_iam_instance_profile.emr_profile.arn
  }

  master_instance_group {
    instance_type  = var.emr_master_instance_type
    instance_count = var.emr_master_count
  }

  core_instance_group {
    instance_type  = var.emr_core_instance_type
    instance_count = var.emr_core_count
  }

  keep_job_flow_alive_when_no_steps = true
  termination_protection            = false
  log_uri                           = "s3://${var.bucket_name}/emr-logs/"

  tags = {
    Name        = "Spark Cluster"
    Environment = "Dev"
  }
}

# Optional: open SSH to EMR master node
resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = var.vpc_security_group_ids[0]
}
