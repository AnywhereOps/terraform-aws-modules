output "outputs" {
  value       = { for k, v in terraform_data.this : k => v.output }
  description = "Map of all outputs, keyed by input key."
}
