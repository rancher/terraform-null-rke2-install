output "server" {
  value = module.server.server
}
output "access" {
  value     = module.access
  sensitive = true
}
output "kubeconfig" {
  value       = module.this.kubeconfig
  description = "Kubernetes config file contents for the cluster."
  sensitive   = true
}
output "rke2_version" {
  value       = var.rke2_version
  description = "Currently installed RKE2 version"
}
