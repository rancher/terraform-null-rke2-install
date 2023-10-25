output "kubeconfig" {
  value     = module.basic_install.kubeconfig
  sensitive = true
}