My personal usb livedisks.

Build using:

# nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix --pure

and then use dd to copy to the usb.

E.g. for some device /dev/sdX (use lsblk to list them).

# dd if=/nix/store/jqjgs9rhsbjin9ss10irll7ir4rnzcb1-nixos-18.09.1400.636b2b2da96-x86_64-linux.iso/iso/nixos-18.09.1400.636b2b2da96-x86_64-linux.iso of=/dev/sdX

After you can resize the partitions.
