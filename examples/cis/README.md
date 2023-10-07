# RPM Install Example

This is a basic install using the "rpm" install method.

Tar is the default deployment method because it is portable across many operating systems, versatile, and independent of the internet.

In this example we are using the "rpm" install method, which involves allowing the server to access the public internet.
This installation method only works on RHEL based OS.

WARNING! This downloads files from the Rancher/Rke2 releases that are a bit large ( >1GB).

This example requires AWS authentication.
Please see the AWS Access and AWS Server modules for more information.
https://registry.terraform.io/modules/rancher/access/aws/latest
https://registry.terraform.io/modules/rancher/server/aws/latest

This example is tested using Terratest, please see the `./tests` directory for more information.
You can run this test by navigating to the `./tests` directory and running `go test -v -parallel=10 -timeout=30m -run TestRpm`.
