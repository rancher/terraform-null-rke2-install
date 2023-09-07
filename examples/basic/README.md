# Basic Example

This is the most basic example of running the module.
WARNING! This downloads files from the Rancher/Rke2 releases that are a bit large ( >1GB).

This example requires AWS and GitHub authentication.
Please see the AWS Access, AWS Server, and RKE2 Download modules for more information.
https://registry.terraform.io/modules/rancher/access/aws/latest
https://registry.terraform.io/modules/rancher/server/aws/latest
https://registry.terraform.io/modules/rancher/rke2-download/github/latest

This example is tested using Terratest, please see the `./tests` directory for more information.
You can run this test by navigating to the `./tests` directory and running `go test -v -parallel=10 -timeout=30m -run TestBasic`.
