output "kubeconfig" {
  value     = module.stable_install.kubeconfig
  sensitive = true
}