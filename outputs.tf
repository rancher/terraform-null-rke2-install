output "kubeconfig" {
  value       = (length(data.file_local.kubeconfig) > 0 ? data.file_local.kubeconfig[0].contents : "not found")
  description = <<-EOT
    The contents of the kubeconfig file.
  EOT
  sensitive   = true
}
