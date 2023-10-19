{
  # validate a flake with 'nix flake check .'
  # alias the use of flakes with: "alias nix='nix --extra-experimental-features nix-command --extra-experimental-features flakes'"
  #  you can also set a config file at ~/.config/nix/nix.conf or /etc/nix.conf, but I wanted to remove that dependency

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
    nixpkgs-terraform.url = "github:/NixOS/nixpkgs/39ed4b64ba5929e8e9221d06b719a758915e619b";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, nixpkgs-terraform, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      # 'legacy' is not bad, it looks for previously imported nixpkgs
      #  this allows idempotent loading of nixpkgs in dependent flakes
      # https://discourse.nixos.org/t/using-nixpkgs-legacypackages-system-vs-import/17462/8
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgs-terraform = nixpkgs-terraform.legacyPackages.${system};
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; with pkgs-terraform; [
            bashInteractive
            git
            terraform
            tflint
            shellcheck
          ];
          shellHook = ''
            source .envrc
          '';
        };
      }
    );
}
