output "kubeconfig" {
  value     = module.TestRpm.kubeconfig
  sensitive = true
}