# Remote Example

In this example, the files to install already exist on the remote server before the install module is called.
In practice, you might be using a call on the remote server to download the files,
or you might have a physical drive attached to the remote server with the files already on it.

This example is tested using Terratest, please see the `./tests` directory for more information.
You can run this test by navigating to the `./tests` directory and running `go test -v -parallel=10 -timeout=30m -run TestRemote`.
