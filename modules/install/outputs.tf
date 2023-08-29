output "kubeconfig" {
  value     = data.local_file.kubeconfig.content
  sensitive = true
}