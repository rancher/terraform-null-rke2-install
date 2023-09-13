output "kubeconfig" {
  value       = (can(data.local_file.kubeconfig[0].content) ? data.local_file.kubeconfig[0].content : null)
  description = <<-EOT
    The contents of the kubeconfig file.
  EOT
  sensitive   = true
}
