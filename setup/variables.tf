variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environments" {
  description = "List of environments to setup"
  type        = list(string)
  default     = ["dev", "staging", "production"]
}

# variable "terraform_state_bucket" {
#   description = "Name of the S3 bucket for Terraform state"
#   type        = string
# }

# variable "terraform_lock_table" {
#   description = "Name of the DynamoDB table for Terraform state locking"
#   type        = string
# }
