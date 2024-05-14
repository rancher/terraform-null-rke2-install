output "kubeconfig" {
  value       = (length(data.local_sensitive_file.kubeconfig) > 0 ? data.local_sensitive_file.kubeconfig[0].content : "not found")
  description = <<-EOT
    The contents of the kubeconfig file.
  EOT
  sensitive   = true
}
