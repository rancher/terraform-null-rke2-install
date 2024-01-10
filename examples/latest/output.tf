output "kubeconfig" {
  value     = module.latest_install.kubeconfig
  sensitive = true
}