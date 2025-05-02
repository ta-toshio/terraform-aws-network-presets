output "deploy_user_name" {
  value       = module.iam.deploy_user_name
  description = "The IAM user created for deployments"
}

output "deploy_user_access_key" {
  value       = module.iam.deploy_user_access_key_id
  description = "The access key ID for the deployment user"
  sensitive   = true
}

output "deploy_user_secret_key" {
  value       = module.iam.deploy_user_secret_access_key
  description = "The secret access key for the deployment user"
  sensitive   = true
}

output "ecr_repositories" {
  value       = module.ecr.repositories
  description = "The ECR repositories created for each environment"
}

# output "terraform_state_bucket" {
#   value       = aws_s3_bucket.terraform_state.bucket
#   description = "The S3 bucket for storing Terraform state"
# }

# output "terraform_lock_table" {
#   value       = aws_dynamodb_table.terraform_locks.name
#   description = "The DynamoDB table for Terraform state locking"
# } 
