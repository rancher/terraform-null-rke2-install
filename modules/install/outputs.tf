output "config" {
  value = (can(local_sensitive_file.install["rke2-config.yaml"]) ? local_sensitive_file.install["rke2-config.yaml"].content : null)
}