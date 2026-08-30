variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "internet_gateway_id" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "nat_gateway_count" {
  type    = number
  default = 3
}

variable "nat_gateway_ids" {
  type    = list(string)
  default = []
}
