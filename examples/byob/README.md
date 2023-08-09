# Bring Your Own Binary Example

In this example, you have chosen to provide your own files rather than the module downloading them from GitHub.
We make some assumptions in order to limit "works on my machine" issues.

## Assumptions:

- you are able to connect to the server you want to install on
- you are not running from the server to install on
- you are running ssh-agent and have loaded the key you want to use to access the server
- you have downloaded the release artifacts you want to install
  - the module will output the expected file list
  - example:

    ```
    <local_path>/
      rke2-images.<system>-<arch>.tar.gz
      rke2.<system>-<arch>.tar.gz
      sha256sum-<arch>.txt
      install.sh
    ```
- you are using the latest version of Terraform
  - minimally version `1.2`, we test on `1.5+`
- AWS Access
  - this example is written to generate objects in AWS to enable the module
  - you need to have AWS access and this may incur an additional cost
  - you do not need AWS access to install RKE2 or to run the module, that is just how this example is written
  - you will need to provide the environment variables to configure the AWS provider appropriately
  - our CI uses a special app level connection to our AWS account, so it might be a bad example
    - the easiest way to configure this is to use the aws cli to configure access
- Public IP Address
  - in order for the aws_access module to work properly it may need to know the public ip address of the server running terraform
  - this is used to generate aws security groups for egress and ingress to only that address
  - the aws_access module will attempt to figure out your public IP address using Curl to `https://ipinfo.io/ip`
    - you may instead specify your public ip address to prevent this
  - this is only necesary for the example, not for the module
- Terraform artifacts: if you don't have a public internet connection you will need to download the terraform providers necessary for this module to work
  - see https://somspeaks.com/terraform-offline-setup-and-initialization/ as a pretty good tutorial
  - official documentation:
    - https://developer.hashicorp.com/terraform/cli/commands/providers/mirror
    - https://developer.hashicorp.com/terraform/cli/config/config-file#explicit-installation-method-configuration

## Dummy GitHub Provider Config

The GitHub provider is written in a way that attempts to reach out to GitHub at plan/refresh time rather than just at apply time.
This means that while GitHub may not be used we need to provide a dummy config to pass the validate checks.
Please see the `versions.tf` for an example of the dummy config.
This will not attempt to make any connections:

```
provider "github" {
  token    = ""
  base_url = "https://localhost"
}
```
