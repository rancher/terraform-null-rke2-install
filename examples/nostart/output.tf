output "kubeconfig" {
  value     = module.install_without_starting.kubeconfig
  sensitive = true
}