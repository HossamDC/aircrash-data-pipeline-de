//---------------------------------------------
// TERRAFORM VARIABLES
//---------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "Name of the AWS CLI profile (optional)"
  type        = string
  default     = ""
}

variable "bucket_name" {
  description = "S3 bucket where raw and processed data live"
  type        = string
}

variable "master_username" {
  description = "Redshift master user"
  type        = string
  default     = "admin"
}

variable "master_password" {
  description = "Redshift master password (sensitive!)"
  type        = string
  sensitive   = true
}

variable "cluster_node_type" {
  description = "Redshift node type"
  type        = string
  default     = "dc2.large"
}

variable "cluster_type" {
  description = "Redshift cluster type"
  type        = string
  default     = "single-node"
}

variable "vpc_id" {
  description = "VPC ID for all networking resources"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for Redshift subnet group"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs for Redshift and EMR"
  type        = list(string)
}

variable "key_name" {
  description = "EC2 Key pair name for EMR SSH"
  type        = string
}

variable "emr_master_instance_type" {
  description = "EMR Master EC2 instance type"
  type        = string
  default     = "m5.xlarge"
}

variable "emr_master_count" {
  description = "EMR Master instance count"
  type        = number
  default     = 1
}

variable "emr_core_instance_type" {
  description = "EMR Core EC2 instance type"
  type        = string
  default     = "m5.xlarge"
}

variable "emr_core_count" {
  description = "EMR Core instance count"
  type        = number
  default     = 2
}
