output "arn" {
  description = "Full ARN of the repository."
  value       = aws_ecr_repository.main.arn
}

output "repository_url" {
  description = "URL of the repository."
  value       = aws_ecr_repository.main.repository_url
}

output "name" {
  description = "Name of the repository."
  value       = aws_ecr_repository.main.name
}
