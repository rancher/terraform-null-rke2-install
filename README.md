# Terraform GitHub RKE2 Installer

WARNING! this module is not ready for use

This module installs RKE2 from local files and optionally will download the required files from GitHub.
If the contents of your config change this module will attempt to install the new config and restart the service.

## Local File Path

The `local_file_path` variable informs the module what to do.

- If the variable indicates a path on the local file system then the module will not attempt to download anything.
- If the value of the variable is "", then the module assumes you need it to download the files, and initiates the GitHub provider to do so.
  - this means that only if you need to download the files will you need the GitHub token

This module does not attempt to alter the contents of files supplied in the `local_file_path` variable.
It tracks the content of *only* the `rke2-config.yaml`, if supplied (it is optional).

## Release

This is the version of rke2 to install, even when supplying the files it is necessary to specify the exact version of rke2 you are installing.

- If the release version changes, this module will attempt to run the installation again. (this may not work)

## RKE2 Config

If not supplying your own files you may provide the string (utf8) contents of your rke2 config using the `rke2_config` variable.
If the value of this variable changes, then the module will copy the new config to the remote server and restart the process.
This allows you to manage your config iteratively and separately from this module.

You may also provide an `rke2-config.yaml` in the local directory specified in `local_file_path` variable.
If the contents of this file change, then this module will detect that, copy the new config to the remote server, and restart the process.
This allows you to manage your config iteratively and separately from this module.

## GitHub Access

The GitHub provider [provides multiple ways to authenticate](https://registry.terraform.io/providers/integrations/github/latest/docs#authentication) with GitHub.
For simplicity we use the `GITHUB_TOKEN` environment variable when testing.
The GitHub provider is not used when `local_file_path` is specified!
This means that you don't need to provide any information to that provider and it will not attempt to make connections.

## Examples

### Local State

The specific use case for the example modules is temporary infrastructure for testing purposes.
With that in mind, it is not expected that we manage the resources as a team, therefore the state files are all stored locally.
If you would like to store the state files remotely, add a terraform backend file (`*.name.tfbackend`) to your implementation module.
https://www.terraform.io/language/settings/backends/configuration#file

## Development and Testing

### Paradigms and Expectations

Please make sure to read [terraform.md](./terraform.md) to understand the paradigms and expectations that this module has for development.

### Environment

It is important to us that all collaborators have the ability to develop in similar environments, so we use tools which enable this as much as possible.
These tools are not necessary, but they can make it much simpler to collaborate.

* I use [nix](https://nixos.org/) that I have installed using [their recommended script](https://nixos.org/download.html#nix-install-macos)
* I use [direnv](https://direnv.net/) that I have installed using brew.
* I simply use `direnv allow` to enter the environment
* I navigate to the `tests` directory and run `go test -v -timeout=5m -parallel=10`
* To run an individual test I navigate to the `tests` directory and run `go test -v -timeout=5m -run <test function name>`
  * eg. `go test -v -timeout=5m -run TestBasic`
* I use `override.tf` files to change the values of `examples` to personalized data so that I can run them.
* I store my GitHub credentials in a local file and generate a symlink to them named `~/.config/github/default/rc`
  * this will be automatically sourced when you enter the nix environment (and unloaded when you leave)

Our continuous integration tests in the GitHub [ubuntu-latest runner](https://github.com/actions/runner-images/blob/main/images/linux/Ubuntu2204-Readme.md), which has many different things installed
