# nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix --pure

# Based on https://github.com/Mic92/dotfiles/blob/6a48eee2c772bd1f52f22fca5f531770958c738f/nixos/images/yubikey-image.nix
# with modifications and additional scripts

{ config, pkgs, lib, ... }:
let
  # My personal keyboard layout scripts
  myKeyboardLayouts = pkgs.callPackage "${myKeyboardLayoutsSrc}" {};
    myKeyboardLayoutsSrc = builtins.fetchurl {
      url = https://gist.githubusercontent.com/rehno-lindeque/1b27db45e445c0efccb086624bbd4205/raw;
    };

  inherit (pkgs.callPackage ./scripts.nix {}) guide help startGuide provision-yubikeys;
in
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-base.nix>

    # Provide nixos initial channel
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];


  # using paperkey raw output and mnemonicode
  # GNUPGHOME=/tmp/ram gpg --export-secret-key testing | paperkey --output-type raw | mnencode | wc -w

  # echo '161288f3198dbb9d282c3b2b3d0eda716750247c33280f4948a14b61bdc168dbf7ffd98713fd943fd52a89be44f1069bd03a8b7bcaea61a8cf136086938210cdd092c43d4ecca07d5ad2a36f26ac666a37d7e2a14519ba811fe60620a912707d06c8a4db0dd49704838b8575af3be3214fbf2fad9c1e3f613d5e2a70' | xxd -r -p - | mnencode  | wc -w

  # Testing the script (NB! Note that it needs padding of zeros to make it work!)
  #
  # nix-shell -p ssss paperkey mnemonicode unixtools.xxd gnupg22
  # GNUPGHOME=/tmp/ram gpg --armor --export-secret-key 54DEF5C343328F9148F0D99A9BDD5677B29C1987 | secret-share-split --threshold 3 --count 5 | tee decode1 | (while read -r l ; do mnemonic "$l"000000 ; done) | tee encode | (while read -r l ; do mnemonic $l ; done) | sed -e 's/[0]*$//g' | tee decode2 | secret-share-combine > secret 
  # [nix-shell:/tmp/ram]$ diffuse decode1 decode2 encode secret

  environment.interactiveShellInit = ''
    ${help}/bin/help
    '';

  environment.systemPackages =
    with pkgs;
    with myKeyboardLayouts;
    [
      yubikey-personalization
      cryptsetup
      pwgen
      midori
      gnupg
      paperkey
      mnemonicode
      unixtools.xxd

      # yubikey guide
      startGuide

      # my personal keyboard layouts
      norman
      jlimaj
      qwerty
    ];


  # # User software
  # environment.systemPackages = with pkgs; [
  #   gparted
  #   sakura
  #   zip
  #   google-chrome
  #   firefox
  #   gnome3.gtk
  #   gnome3.gnome_settings_daemon
  #   gnome3.nautilus
  #   gnome3.eog
  #   gnome3.gnome-screenshot
  #   vim
  #   silver-searcher
  # ];

  services.udev.packages = with pkgs; [ yubikey-personalization ];
  services.pcscd.enable = true;
  users.users.root.initialHashedPassword = "";

  # make sure we are air-gapped
  networking.networkmanager.enable = false;
  networking.wireless.enable = false;
  networking.dhcpcd.enable = false;

  services.mingetty.helpLine = "The 'root' account has an empty password.";

  # Unfree software (drivers etc)
  nixpkgs.config.allowUnfree = true;

  services = {
    xserver = {
      enable = true;
      autorun = lib.mkForce true;
      displayManager.slim = {
        enable = true;
        defaultUser = "root";
        autoLogin = true;
      };
      desktopManager.plasma5 = {
        enable = true;
        enableQt4Support = false;
      };
      # desktopManager.gnome3 = {
      #   enable = true;
      # };
      # displayManager.slim.enable = lib.mkForce false;
      # displayManager.gdm.autoLogin = {
      #   enable = true;
      #   user = "root";
      # };
      # Enable touchpad support for many laptops.
      # synaptics.enable = true;
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_4_14; # 4_14 is an LTS release
  };

  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";

  # fileSystems = {
  #   "/root" = {
  #     device = "/dev/disk/by-label/home";
  #     fsType = "ext4";
  #   };
  # };

}
