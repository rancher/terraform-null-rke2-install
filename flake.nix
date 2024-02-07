{
  # validate a flake with 'nix flake check .'
  # alias the use of flakes with: "alias nix='nix --extra-experimental-features nix-command --extra-experimental-features flakes'"

  # WARNING! this is linux/mac only!
  description = "A reliable testing environment";

  # https://status.nixos.org/ has the latest channels, it is recommended to use a commit hash
  # https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html
  # to find: go to github/NixOS/nixpkgs repo

  # select a commit hash or "revision"
  #inputs.nixpkgs.url = "nixpkgs/92fe622fdfe477a85662bb77678e39fa70373f13";

  # select a tag
  #inputs.nixpkgs.url = "github:NixOS/nixpkgs/21.11";

  # select packages from another flake
  #inputs.nixpkgs.follows = "nixpkgs/0228346f7b58f1a284fdb1b72df6298b06677495";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      # 'legacy' is not bad, it looks for previously imported nixpkgs
      #  this allows idempotent loading of nixpkgs in dependent flakes
      # https://discourse.nixos.org/t/using-nixpkgs-legacypackages-system-vs-import/17462/8
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # get "updatecli" tar from release, unpack it, and add it to shell
        updatecli-version = {
          "selected" = "v0.66.0";
        };
        updatecli-prep = {
          "x86_64-darwin"   = {
            "url" = "https://github.com/updatecli/updatecli/releases/download/${updatecli-version.selected}/updatecli_Darwin_x86_64.tar.gz";
            "sha" = "sha256-AkYYaCp/a4KkZ4zcYc3GepllyPE6bHb7x7K25JSyljY=";
          };
          "aarch64-darwin"  = {
            "url" = "https://github.com/updatecli/updatecli/releases/download/${updatecli-version.selected}/updatecli_Darwin_arm64.tar.gz";
            "sha" = "sha256-5ctfz4DcHRmjImYzL9hgOaC9pyeYKQxkpdIAr3J1a6g=";
          };
          "x86_64-linux"    = {
            "url" = "https://github.com/updatecli/updatecli/releases/download/${updatecli-version.selected}/updatecli_Linux_x86_64.tar.gz";
            "sha" = "sha256-tmboI0ew+LApo3uLVqebaa8VA/6rgonGJH2onQEbSyk=";
          };
        };
        updatecli = pkgs.runCommand "updatecli-${updatecli-version.selected}" {} ''
          cp ${pkgs.fetchzip { # when fetching archives use fetchzip instead of fetchurl to automatically unpack
            url = updatecli-prep."${system}".url;
            sha256 = updatecli-prep."${system}".sha;
            stripRoot = false;
          }}/updatecli $out
          chmod +x $out
        '';
        updatecli-wrapper = pkgs.writeShellScriptBin "updatecli" ''
          exec ${updatecli} "$@"
        '';

        # get "leftovers" bin from release and add it to shell
        leftovers-version = {
          # remember when updating the version to also update the shas
          # to get the sha, download the file and run 'nix hash file <file>'
          "selected" = "v0.70.0";
        };
        leftovers-prep = {
          "x86_64-darwin"   = {
            "url" = "https://github.com/genevieve/leftovers/releases/download/${leftovers-version.selected}/leftovers-${leftovers-version.selected}-darwin-amd64";
            "sha" = "sha256-HV12kHqB14lGDm1rh9nD1n7Jvw0rCnxmjC9gusw7jfo=";
          };
          "aarch64-darwin"  = {
            "url" = "https://github.com/genevieve/leftovers/releases/download/${leftovers-version.selected}/leftovers-${leftovers-version.selected}-darwin-arm64";
            "sha" = "sha256-Tw7G538RYZrwIauN7kI68u6aKS4d/0Efh+dirL/kzoM=";
          };
          "x86_64-linux"    = {
            "url" = "https://github.com/genevieve/leftovers/releases/download/${leftovers-version.selected}/leftovers-${leftovers-version.selected}-linux-amd64";
            "sha" = "sha256-D2OPjLlV5xR3f+dVHu0ld6bQajD5Rv9GLCMCk9hXlu8=";
          };
        };
        leftovers = pkgs.runCommand "leftovers-${leftovers-version.selected}" {} ''
          cp ${pkgs.fetchurl {
            url = leftovers-prep."${system}".url;
            sha256 = leftovers-prep."${system}".sha;
          }} $out
          chmod +x $out
        '';
        leftovers-wrapper = pkgs.writeShellScriptBin "leftovers" ''
          exec ${leftovers} "$@"
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            actionlint
            bashInteractive
            curl
            git
            gitleaks
            go # need go for terratest
            gnupg # need gpg for signing commits
            jq
            less
            openssh # need openssh for running remote provisioners
            shellcheck
            tflint
            tfswitch
            vim
          ];
          shellHook = ''
            homebin=$HOME/bin;
            install -d $homebin;
            tfswitch -b $homebin/terraform 1.5.7 &>/dev/null;
            export PATH="${updatecli-wrapper}/bin:${leftovers-wrapper}/bin:$homebin:$PATH";
            export PS1="nix:# ";
          '';
        };
      }
    );
}
