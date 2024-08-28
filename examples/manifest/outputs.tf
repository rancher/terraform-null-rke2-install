output "server" {
  value = module.server.server
}
output "image" {
  value = module.server.image
}
output "access" {
  value = module.access
}
output "kubeconfig" {
  value       = module.this.kubeconfig
  description = "Kubernetes config file contents for the cluster."
  sensitive   = true
}
