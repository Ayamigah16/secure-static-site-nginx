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
  description = "Path to SSH public key file (only used if create_key_pair is true)"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "create_key_pair" {
  description = "Whether to create a new key pair or use existing one"
  type        = bool
  default     = true
}

variable "existing_key_pair_name" {
  description = "Name of existing AWS key pair (only used if create_key_pair is false)"
  type        = string
  default     = ""
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
