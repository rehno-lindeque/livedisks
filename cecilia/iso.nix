# nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix --pure

{ config, pkgs, lib, ... }:
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-base.nix>

    # Provide nixos initial channel
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  # Unfree software (drivers etc)
  nixpkgs.config.allowUnfree = true;

  # Enable SSH during boot process
  # systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDihi25C12vUNxZyxAFVo4lZ4R0bSFmTcNfPQl4mrwNf7116dSMcRilBmkG/x0/G5PRtfz8B+OajtZbK2ivjTwYoDL5+DX50X8jCI4sTjOWBXsw8KcAEu/8NcaIl38tq170YChjUomb3PNqzIvR7fFLAqYxlk01T/42m388WNA2IDTFv1Ex0fkuVOKXnW3ULSZdzLRe7Eh6sSA2qOucue8p+uHgKc9Q9CRhWEkik+iUPO2gTC39LDnMDDtkbeFz6P3R8652kwTSNxV//6FlU0zvvynmxiKjdYUUdWtbkkTZDrH4c5fs6WDem+VfKechS3pvbGQXxcWtYivcgWPDBs9NGyZy0118COhTHF+mgL1jxCu+0Dxfz3/XHS1Efg8rVICI9xjcn2X17ammqWBzsd9navGCXCIJZQQYJSDkU2qUy8anc0834ay88q6wbtcjhXHLmZm/EU+3/B5n54cbTv+zH5EB02dfX/1e7vM1isHvKraKq29HUrY9olmQqf43LjBtE1eoAFXo/tfWDg2aWMvUxXVVYWJ2Q3anyKRlaeN5Mo02uFsusCmRNs7r6lBC0OFbKnkLIG2s0i3BqqVGBV+UctktpmrUZRzhL7o6oiTAhAiKv4ns3B7Yk86JlEW9qkhoysgr4KjsFZD7phg5TDl8ECz+rKT8ZXIRLfXQMOzsOQ== rehno.lindeque@gmail.com"
  ];

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
      synaptics.enable = true;
    };
    openssh = {
      enable = true;
      extraConfig = ''
        MaxAuthTries 10
      '';
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_4_14; # 4_14 is an LTS release
  };

  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";

  fileSystems = {
    "/root" = {
      device = "/dev/disk/by-label/home";
      fsType = "ext4";
    };
  };

  # User software
  environment.systemPackages = with pkgs; [
    gparted
    sakura
    zip
    google-chrome
    firefox
    keybase
    gnome3.gtk
    gnome3.gnome_settings_daemon
    gnome3.nautilus
    gnome3.eog
    gnome3.gnome-screenshot
    vlc
    gimp
    blender
    inkscape
    libreoffice
    gnumeric
    wget
    vim
    silver-searcher
    kate
  ];
}
