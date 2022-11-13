{
  description = "A Cpp2 to Cpp1 Transpiler";

  inputs = {
    # Nixpkgs / NixOS version to use.
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in

    {


      # A Nixpkgs overlay.
      overlay = final: prev: {

        cppfront = prev.pkgs.llvmPackages_12.stdenv.mkDerivation rec {
          name = "cppfront-${version}";

          src = ./source;

          buildPhase = ''
            clang++ cppfront.cpp -std=c++20 -o cppfront
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp cppfront $out/bin
          '';
        };

      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) cppfront;
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.cppfront);
    };
}
