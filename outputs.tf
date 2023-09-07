output "kubeconfig" {
  value       = data.local_file.kubeconfig.content
  description = <<-EOT
    The contents of the kubeconfig file.
  EOT
  sensitive   = true
}
