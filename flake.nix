{
  description = "A reliable testing environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-darwin" "aarch64-darwin" "x86_64-linux" ]
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          leftovers-version = {
            "selected" = "v0.70.0";
          };
          leftovers-prep = {
            "x86_64-darwin" = {
              "url" = "https://github.com/genevieve/leftovers/releases/download/${leftovers-version.selected}/leftovers-${leftovers-version.selected}-darwin-amd64";
              "sha" = "sha256-HV12kHqB14lGDm1rh9nD1n7Jvw0rCnxmjC9gusw7jfo=";
            };
            "aarch64-darwin" = {
              "url" = "https://github.com/genevieve/leftovers/releases/download/${leftovers-version.selected}/leftovers-${leftovers-version.selected}-darwin-arm64";
              "sha" = "sha256-Tw7G538RYZrwIauN7kI68u6aKS4d/0Efh+dirL/kzoM=";
            };
            "x86_64-linux" = {
              "url" = "https://github.com/genevieve/leftovers/releases/download/${leftovers-version.selected}/leftovers-${leftovers-version.selected}-linux-amd64";
              "sha" = "sha256-D2OPjLlV5xR3f+dVHu0ld6bQajD5Rv9GLCMCk9hXlu8=";
            };
          };
          leftovers = pkgs.stdenv.mkDerivation {
            name = "leftovers-${leftovers-version.selected}";
            src = pkgs.fetchurl {
              url = leftovers-prep."${system}".url;
              sha256 = leftovers-prep."${system}".sha;
            };
            phases = [ "installPhase" ];
            installPhase = ''
              mkdir -p $out/bin
              cp $src $out/bin/leftovers
              chmod +x $out/bin/leftovers
            '';
          };

        terraform-version = {
          "selected" = "1.5.7";
        };
        terraform-prep = {
          "x86_64-darwin" = {
            "url" = "https://releases.hashicorp.com/terraform/${terraform-version.selected}/terraform_${terraform-version.selected}_darwin_amd64.zip";
            "sha" = "sha256-R2t/sP+f403E7WlO8oO2zI/gSnb9Q4V3yV78R4oD+rI="; # You may need to update this sha if using an intel mac
            "checksum" = "d142d10c01a2380a0de24ea64214f7620eb5e8d98dffde6414902c2e646d6fc3";
          };
          "aarch64-darwin" = {
            "url" = "https://releases.hashicorp.com/terraform/${terraform-version.selected}/terraform_${terraform-version.selected}_darwin_arm64.zip";
            "sha" = "sha256-23wz6xpEa3OkQ+LFW1MoRfe3DNVhAL7EyW8Vz6tfUMs=";
            "checksum" = "db7c33eb1a446b73a443e2c55b532845f7b70cd56100bec4c96f15cfab5f50cb";
          };
          "x86_64-linux" = {
            "url" = "https://releases.hashicorp.com/terraform/${terraform-version.selected}/terraform_${terraform-version.selected}_linux_amd64.zip";
            "sha" = "sha256-wO17wy7lKuJVr5mCyMiKekxhBIXPHVX+6wN+q3X6CCw=";
            "checksum" = "c0ed7bc32ee52ae255af9982c8c88a7a4c610485cf1d55feeb037eab75fa082c";
          };
          # linux container running on darwin or arm linux
          "aarch64-linux" = {
            "url" = "https://releases.hashicorp.com/terraform/${terraform-version.selected}/terraform_${terraform-version.selected}_linux_arm64.zip";
            "sha" = "sha256-9LStfGtgiJYKZn40SVyuSQ+wcpR6n/Jmv1kp9TM1ZeQ=";
            "checksum" = "f4b4ad7c6b6088960a667e34495cae490fb072947a9ff266bf5929f5333565e4";
          };
        };
        terraform = pkgs.stdenv.mkDerivation {
          name = "terraform-${terraform-version.selected}";
          src = pkgs.fetchurl {
            url = terraform-prep."${system}".url;
            sha256 = terraform-prep."${system}".sha;
          };
          checksum = terraform-prep."${system}".checksum;
          nativeBuildInputs = [ pkgs.unzip ];
          phases = [ "installPhase" ];
          installPhase = ''
            echo "$checksum  $src" | sha256sum -c -
            install -d $out/bin
            unzip -o $src -d $out/bin
            chmod +x $out/bin/terraform
          '';
        };

        devPackages = [
          # place our downloaded packages here
          leftovers
          terraform
        ] ++ (with pkgs; [
          # here are the packages from the nix repository
          actionlint
          age
          awscli2
          bashInteractive
          cspell
          curl
          dig
          eslint
          gh
          git
          gitleaks
          gnupg
          go
          golangci-lint
          goreleaser
          gotestfmt
          gotestsum
          jq
          less
          openssh
          openssl
          shellcheck
          tflint
          tfsec
          trivy
          updatecli
          vim
          which
          yq
        ]);

        devShellPackage = pkgs.symlinkJoin {
          name = "dev-shell-package";
          paths = devPackages;
          };
        in
        {
          packages.default = devShellPackage;

          devShells.default = pkgs.mkShell {
            buildInputs = [ devShellPackage ];
            shellHook = ''
              export PS1="nix:# ";
            '';
          };
        }
      );
}
