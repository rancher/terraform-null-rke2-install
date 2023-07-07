locals {
  types = {
    # the installer refers to these as suffixes (types = $SUFFIX in install.sh)
    linux-amd64 = {
      arch = "amd64"
      downloads = {
        "rke2-images.linux-amd64.tar.gz" = { file = "rke2-images.tar.gz" }
        "rke2.linux-amd64.tar.gz"        = { file = "rke2.tar.gz" }
        "sha256sum-amd64.txt"            = { file = "sha256sum.txt" }
        "install.sh" = {
          file = "rke2-install"
          url  = "https://raw.githubusercontent.com/rancher/rke2/master/install.sh"
        }
      }
    }
    linux-s390x = {
      arch = "s390x"
      downloads = {
        "rke2-images.linux-s390x.tar.gz" = { file = "rke2-images.tar.gz" }
        "rke2.linux-s390x.tar.gz"        = { file = "rke2.tar.gz" }
        "sha256sum-s390x.txt"            = { file = "sha256sum.txt" }
        "install.sh" = {
          file = "rke2-install"
          url  = "https://raw.githubusercontent.com/rancher/rke2/master/install.sh"
        }
      }
    }
    windows-ltsc2022-amd64 = {
      arch = "amd64"
      downloads = {
        "rke2-windows-ltsc2022-amd64-images.tar.gz" = { file = "rke2-images.tar.gz" }
        "rke2.windows-amd64.tar.gz"                 = { file = "rke2.tar.gz" }
        "sha256sum-amd64.txt"                       = { file = "sha256sum.txt" }
        "install.ps1" = {
          file = "rke2-install"
          url  = "https://raw.githubusercontent.com/rancher/rke2/master/install.ps1"
        }
      }
    }
    windows-1890-amd64 = {
      arch = "amd64"
      downloads = {
        "rke2-windows-1890-amd64-images.tar.gz" = { file = "rke2-images.tar.gz" }
        "rke2.windows-amd64.tar.gz"             = { file = "rke2.tar.gz" }
        "sha256sum-amd64.txt"                   = { file = "sha256sum.txt" }
        "install.ps1" = {
          file = "rke2-install"
          url  = "https://raw.githubusercontent.com/rancher/rke2/master/install.ps1"
        }
      }
    }
  }
}
