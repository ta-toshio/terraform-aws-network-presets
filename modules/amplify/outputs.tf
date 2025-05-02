output "app_id" {
  description = "AmplifyアプリケーションID"
  value       = aws_amplify_app.frontend.id
}

output "app_arn" {
  description = "AmplifyアプリケーションARN"
  value       = aws_amplify_app.frontend.arn
}

output "default_domain" {
  description = "Amplifyのデフォルトドメイン"
  value       = aws_amplify_app.frontend.default_domain
}

output "branch_id" {
  description = "デプロイされたブランチID"
  value       = aws_amplify_branch.main.id
} 