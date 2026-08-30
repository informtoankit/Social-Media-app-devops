variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be dev, qa, or prod."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "availability_zones" {
  description = "List of AZs — production requires minimum 3 for HA"
  type        = list(string)
}

variable "nat_gateway_count" {
  description = "Number of NAT gateways — 3 for HA (recommended for all envs including dev)"
  type        = number
  default     = 3
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs for observability"
  type        = bool
  default     = true
}

variable "node_instance_type" {
  description = "EKS node instance type — scales per environment"
  type        = string
  default     = "t3.small"
}

variable "node_count" {
  description = "Number of EKS worker nodes — scales per environment"
  type        = number
  default     = 1
}
