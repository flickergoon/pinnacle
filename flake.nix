{
  description = "A WIP Smithay-based Wayland compositor, inspired by AwesomeWM and configured in Lua or Rust";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, fenix, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        fenixPkgs = fenix.packages.${system};
        toolchain = fenixPkgs.stable;
        combinedToolchain = toolchain.completeToolchain;

        # Example build of your compositor crate:
        myCompositor = pkgs.rustPlatform.buildRustPackage {
          pname = "my-compositor";
          version = "unstable";

          src = ./.;

          cargoLock.lockFile = ./Cargo.lock;

          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = with pkgs; [
            wayland
            seatd.dev
            systemdLibs.dev
            libxkbcommon
            libinput
            mesa
            xwayland
            libdisplay-info
            protobuf
          ];
        };
      in {
        packages = {
          default = myCompositor; # exposed as `#default`
          my-compositor = myCompositor; # exposed as `#my-compositor`
        };

        formatter = pkgs.nixfmt;

        devShell = pkgs.mkShell {
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = with pkgs; [
            combinedToolchain
            rust-analyzer
            cargo-outdated
            (writeScriptBin "wlcs" ''
              #!/bin/sh
              ${wlcs}/libexec/wlcs/wlcs "$@"
            '')
            wayland
            protobuf
            lua54Packages.luarocks
            seatd.dev
            systemdLibs.dev
            libxkbcommon
            libinput
            mesa
            xwayland
            libdisplay-info
            xorg.libXcursor
            xorg.libXrandr
            xorg.libXi
            xorg.libX11
          ];

          runtimeDependencies = with pkgs; [
            wayland
            mesa
            libglvnd
          ];

          LD_LIBRARY_PATH = "${pkgs.wayland}/lib:${pkgs.libGL}/lib:${pkgs.libxkbcommon}/lib";
        };
      });
}
