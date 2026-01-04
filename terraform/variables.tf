variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "secure-static-site"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file (only used if generate_ssh_key is false)"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "generate_ssh_key" {
  description = "Whether to generate a new SSH key pair (if true, ignores ssh_public_key_path)"
  type        = bool
  default     = true
}

variable "ssh_key_output_path" {
  description = "Path to save generated private key (only used if generate_ssh_key is true)"
  type        = string
  default     = "./ssh-keys"
}

variable "ssh_allowed_cidr" {
  description = "CIDR blocks allowed to SSH (use your IP for security)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change this to your IP for better security
}

variable "vpc_id" {
  description = "VPC ID (leave empty to use default VPC)"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID (leave empty to use default subnet)"
  type        = string
  default     = ""
}

variable "use_elastic_ip" {
  description = "Whether to allocate and associate an Elastic IP"
  type        = bool
  default     = true
}

variable "deploy_user" {
  description = "Username for deployment (created by user-data script)"
  type        = string
  default     = "ubuntu"
}

variable "ami_id" {
  description = "AMI ID to use (leave empty to auto-detect latest Ubuntu 24.04 LTS). Required if AWS account lacks ec2:DescribeImages permission"
  type        = string
  default     = ""
}
