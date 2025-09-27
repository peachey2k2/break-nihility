{
  inputs = {
    nixpkgs.url = "nixpkgs/25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            gcc
            pkg-config
            scons

            mesa
            libGL
            xorg.libX11
            xorg.libXrandr
            xorg.libXinerama
            xorg.libXcursor
            xorg.libXi
            # xorg.libXext
            # xorg.xorgproto
          ];

          shellHook = ''
            echo "Environment ready"
          '';
        };
      });
}
