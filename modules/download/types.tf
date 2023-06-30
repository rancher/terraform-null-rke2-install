locals {
  types = {
    linux-amd64 = {
      downloads = {
        "rke2-images.linux-amd64.tar.gz" = "rke2-images.tar.gz"
        "rke2.linux-amd64.tar.gz"        = "rke2.tar.gz",
      },
    },
    linux-s390x = {
      downloads = {
        "rke2-images.linux-s390x.tar.gz" = "rke2-images.tar.gz",
        "rke2.linux-s390x.tar.gz"        = "rke2.tar.gz",
      }
    },
    windows-amd64 = {
      downloads = {
        "rke2-windows-1809-amd64-images.tar.gz" = "rke2-images.tar.gz",
        "rke2.windows-amd64.tar.gz"             = "rke2.tar.gz",
      }
    },
  }
}