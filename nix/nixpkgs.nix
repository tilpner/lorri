{ enableMozillaOverlay ? false }:
let
  srcDef = builtins.fromJSON (builtins.readFile ./nixpkgs.json);
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${srcDef.rev}.tar.gz";
    sha256 = srcDef.sha256;
  };

  # provides buildSandbox
  vuizvui = import (builtins.fetchTarball {
    # 2019-04-18, buildSandbox patches
    url = "https://github.com/openlab-aux/vuizvui/archive/09dc1d8ad625b9a1d5b89593b184d316837ba1cc.tar.gz";
    sha256 = "1aa40y3qjlzsny7k1l6f360i999h49j92mgvsbi0c4syw0fkm703";
  }) {};

  # The Mozilla overlay exposes dynamic, constantly updating
  # rust binaries for development tooling. Not recommended
  # for production or CI builds, but is right now the best way
  # to get Clippy, since Clippy only compiles withm Nighly :(.
  #
  # Note it exposes the overlay at:
  #
  #    latest.rustChannels.stable.rust
  #
  # and has a corresponding attrset for nightly.
  mozilla-overlay =
    import
  (
    builtins.fetchTarball
    https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz
  );

  our-overlay = self: super: {

    mdsh = super.rustPlatform.buildRustPackage rec {
      name = "mdsh-${version}";
      version = "unreleased";

      src = super.fetchFromGitHub {
        owner = "zimbatm";
        repo = "mdsh";
        # 2018-04-18, fail on failing commands and show stderr
        rev = "0650c21f833deb8993007e285d6219fd2279d58d";
        sha256 = "1rjfik9rxksydgqjh5g9irz75x7jy00v23d8by4jgdi16xjcbbsy";
      };


      cargoSha256 = "1i2xrwsypnzllby4yag7h9h64fppig7vrkndaj7pyxdr4vp9kv0h";
    };

    buildSandbox = vuizvui.pkgs.buildSandbox;

  };

in import nixpkgs {
  overlays =
    [ our-overlay ]
    ++ (if enableMozillaOverlay then [ mozilla-overlay ] else []);
}
