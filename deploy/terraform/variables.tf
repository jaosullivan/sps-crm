variable "aws_region" {
  type        = string
  description = "AWS region for greenfield stack"
  default     = "ap-southeast-1"
}

variable "environment" {
  type        = string
  description = "Environment name (tags + resource names)"
  default     = "prod"
}

variable "project" {
  type        = string
  default     = "sps-crm"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.40.0.0/16"
}

variable "cluster_name" {
  type        = string
  default     = "sps-crm"
}

variable "db_name" {
  type        = string
  default     = "sps_crm"
}

variable "db_username" {
  type        = string
  default     = "sps"
}

variable "public_host" {
  type        = string
  description = "Public HTTPS hostname for ALB / CORS (fill before apply)"
  default     = "crm.example.com"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM cert ARN in this region for the public host (empty until issued)"
  default     = ""
}
