# Download Install Files

This module downloads the files necessary for install.
It should only download, not process or unpack.
It downloads to the local directory, not a remote server, please make sure you have the available storage space.

## FAQ

### Why separate the download and install processes?

- this separation of concerns allows us to more easly manage different kinds of server configurations
- we can normalize the install process by downloading only the proper files and moving them over to the proper locations

### Why are you using an external provider?

- the http provider has a max download size of 100MB (images archive is > 1GB)
- null resources would need a trigger to run when a file is deleted outside of terraform
- we couldn't find a way to download files like this with the built-in providers

### What are the trade-offs of using the external provider?

- external provider requires a script to be run on the local machine (the machine running terraform)
- external provider requires the local machine to have the required tools installed
- external provider requires the local machine to have access to the internet
- external provider is a "data" resource, so it runs at plan/refresh/compile time, not apply time

### Why not use the installer to download the proper files?

- we don't want to assume that the server you are installing on has public internet access
  - this allows us to satisfy both normal and "air-gapped" installs more easily
- the installer assumes the system you are running it on is the system you are installing to
- the installer uses local system information to determine which files to download
- there is a chicken egg issue with downloading the installer and running it in the same terraform apply
