# For testing
{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs.callPackage ./scripts.nix {}) help guide-readme guide-html browse-guide-html browse-guide-readme setup-gpg provision-yubikeys-gpg provision-yubikeys-ssh;
in
  pkgs.mkShell {
    shellHook = "${help}/bin/help";
    buildInputs = [
      help
      browse-guide-html
      browse-guide-readme
      setup-gpg
      provision-yubikeys-gpg
      provision-yubikeys-ssh
    ];
  }

