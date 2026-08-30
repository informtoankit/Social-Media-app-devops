variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "allowed_origins" {
  description = "List of websites/domains allowed to directly interact with this S3 bucket (CORS)"
  type        = list(string)
  default     = ["*"]
}
