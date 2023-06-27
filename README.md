# Terraform GitHub RKE2 Installer

This module uses the official GitHub provider to download RKE2 artifacts and install RKE2 on a server provided.
It starts the RKE2 service and will join a cluster, but provides only rudimentary configuration.
To manage your RKE2 cluster using Terraform, please see our terraform-kubernetes-rke2 module,
which uses the hashicorp/kubernetes provider to configure an RKE2 cluster.
When testing we don't expect the RKE2 node to pick up workloads automatically, the cluster configuration should decide how to use new nodes.

This is a "Core Module", it shouldn't contain any nested "independent modules". Please see [terraform.md](./terraform.md) for more information.

## Requirements

### GitHub Access

The GitHub provider [provides multiple ways to authenticate](https://registry.terraform.io/providers/integrations/github/latest/docs#authentication) with GitHub.
For simplicity we use the `GITHUB_TOKEN` environment variable when testing.

### Nix

These modules use Nix the OS agnostic package manager to install and manage local package dependencies,
 install Nix and source the .envrc to enter the environment.
The .envrc will load a Nix development environment (a Nix shell), using the flake.nix file.
You can easily add or remove dependencies by updating that file, the flake.lock is a lock file to cache dependencies.
After loading the Nix shell, Nix will source the .envrc, setting all of the environment variables as necessary.

## Local State

The specific use case for the example modules here is temporary infrastructure for testing purposes.
With that in mind it is not expected that the user will manage the resources as a team, therefore the state files are all stored locally.
If you would like to store the state files remotely, add a terraform backend file (`*.name.tfbackend`) to your implementation module.
https://www.terraform.io/language/settings/backends/configuration#file

## Override Tests

You may want to test this code with slightly different parameters for your environment.
Check out [Terraform override files](https://developer.hashicorp.com/terraform/language/files/override) as a clean way to modify the inputs without accidentally committing any personalized code.
