output "kubeconfig" {
  value     = module.TestBasic.kubeconfig
  sensitive = true
}