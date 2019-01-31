My personal usb livedisks.

Build an iso using:

# nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix --pure

and then use dd to copy to the usb.

E.g. for some device /dev/sdX (use lsblk to list them).

# dd if=result/iso/nixos-18.09.1400.636b2b2da96-x86_64-linux.iso of=/dev/sdX bs=1MB
# sync

Add a new linux partition.

# umount /dev/sdX1 /dev/sdX2
# fdisk /dev/sdX

    Command (m for help): n
    Partition type
       p   primary (2 primary, 0 extended, 2 free)
       e   extended (container for logical partitions)
    Select (default p): p
    Partition number (3,4, default 3):
    First sector (2562048-31336447, default 2562048):
    Last sector, +sectors or +size{K,M,G,T,P} (2562048-31336447, default 31336447):

    Created a new partition 3 of type 'Linux' and of size 13.7 GiB.

    Command (m for help): w
    The partition table has been altered.
    Calling ioctl() to re-read partition table.
    Re-reading the partition table failed.: Device or resource busy

    The kernel still uses the old table. The new table will be used at the next reboot or after you run partprobe(8) or kpartx(8).

# sync

Unplug the usb and reinsert it to work around linux kernel not picking up the new partition.

Format the new linux partition as ext4 with label "home".

# umount /dev/sdX1 /dev/sdX2 /dev/sdX3
# mkfs.ext4 -L home /dev/sdX3
# sync

