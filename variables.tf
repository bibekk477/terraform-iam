# String type
variable "environment" {
  type        = string
  description = "The environment type"
  default     = "prod"
}
variable "localstack_endpoint" {
  type        = string
  description = "LocalStack endpoint URL"
  default     = "http://localhost:4566"
}
variable "aws_region" {
  type        = string
  description = "AWS region for resources"
  default     = "us-east-1"
}
