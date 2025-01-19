{
  description = "A basic Rust devshell for NixOS users developing Leptos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
        url = "github:oxalica/rust-overlay";
        inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, rust-overlay, ... }:
  let
    lib = nixpkgs.lib;
    systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

    forEachSystem = fn: lib.genAttrs systems (system: let
      overlays = [ (import rust-overlay) ];
      pkgs = import nixpkgs { inherit system overlays; };
    in fn { inherit pkgs; } );

    mkRustToolchain = pkgs: pkgs.rust-bin.selectLatestNightlyWith (t: t.minimal.override {
      extensions= [ "rust-src" "rust-analyzer" ];
      targets = [ "wasm32-unknown-unknown" ];
    });
  in {
    devShells = forEachSystem ({ pkgs }: {
      default = pkgs.mkShell {
        name = "leptos";

        buildInputs = with pkgs; [
          openssl
          pkg-config
          cacert
          (mkRustToolchain pkgs)
        ] ++ pkgs.lib.optionals pkg.stdenv.isDarwin [
          darwin.apple_sdk.frameworks.SystemConfiguration
        ];

        # Tools
        packages = with pkgs; [
          cargo-make
          trunk
        ];
      };
    });
  };
}
