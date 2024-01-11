output "kubeconfig" {
  value     = module.TestCis.kubeconfig
  sensitive = true
}