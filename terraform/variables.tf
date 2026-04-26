variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type — t3.medium gives 2 vCPUs and 2 GB RAM for microk8s"
  type        = string
  default     = "t3.small"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI for us-east-1"
  type        = string
  # This is the official Canonical Ubuntu 22.04 AMI for us-east-1.
  # If you use a different region, look up the correct AMI in the AWS console.
  default     = "ami-0c7217cdde317cfec"
}

variable "public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/project3-key.pub"
}

variable "key_name" {
  description = "Name for the AWS key pair"
  type        = string
  default     = "project3-keypair"
}

