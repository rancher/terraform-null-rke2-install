# RKE2 Upgrade Example

This example demonstrates how to upgrade RKE2 to a new version using this module.

## How Upgrades Work

The module automatically handles RKE2 upgrades when the `rke2_version` variable changes:

1. **Version Change Detection**: The `identifier` variable includes `rke2_version` in its MD5 hash
2. **Trigger Reinstall**: When the version changes, the identifier changes, triggering the module to run
3. **Upgrade Process**:
   - Stops the RKE2 service
   - Installs the new RKE2 version
   - Reboots the server
   - Starts RKE2 with the new version

## Initial Deployment

Deploy RKE2 v1.34.6+rke2r3:

```bash
export TF_VAR_identifier="upgrade-$(date +%s)"
export TF_VAR_key="$(cat ~/.ssh/id_rsa.pub)"
export TF_VAR_key_name="your-aws-key-name"
export TF_VAR_rke2_version="v1.34.6+rke2r3"

terraform init
terraform apply
```

## Upgrading RKE2

To upgrade to v1.35.3+rke2r3:

1. **Change the version** in `terraform.tfvars` or via environment variable:
   ```bash
   export TF_VAR_rke2_version="v1.35.3+rke2r3"
   ```

2. **Apply the change**:
   ```bash
   terraform apply
   ```

3. **Monitor the upgrade**:
   - Terraform will show the resources being recreated
   - The server will reboot during the upgrade
   - Wait for the apply to complete

4. **Verify the new version**:
   ```bash
   kubectl version --kubeconfig=./data/${TF_VAR_identifier}/kubeconfig
   ```

## Version Pinning Best Practice

This example uses **version pinning** (e.g., `v1.34.6+rke2r3`) rather than channels like "stable" or "latest". This approach:

- ✅ Provides predictable, controlled upgrades
- ✅ Allows testing upgrades in dev before production
- ✅ Prevents unexpected version changes
- ✅ Makes rollbacks explicit (change version back)

## Available Versions

Find available RKE2 versions at:
- https://github.com/rancher/rke2/releases
- Or via API: https://update.rke2.io/v1-release/channels

## Important Notes

- **Data Persistence**: RKE2 data in `/var/lib/rancher/rke2` persists across upgrades
- **Etcd Safety**: Single-node clusters upgrade safely; multi-node requires more planning
- **Downtime**: Expect ~2-5 minutes of downtime during the upgrade
- **Testing**: Always test upgrades in a non-production environment first

## Cleanup

```bash
terraform destroy
```
