output "kubeconfig" {
  value     = module.candidate_install.kubeconfig
  sensitive = true
}