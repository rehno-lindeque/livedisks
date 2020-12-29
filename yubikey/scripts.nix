# nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix --pure

{ stdenv, fetchurl, fetchFromGitHub, writeScript, writeShellScriptBin, pandoc, mdcat, midori, lsb-release, usbutils }:

let
  # Bash colors
  nc="\\e[0m"; # No Color
  white="\\e[1;37m";
  brown="\\e[0;33m";
  yellow="\\e[1;33m";
  bright_red="\\e[1;31m";
  bright_blue="\\e[1;34m";
  bright_cyan="\\e[1;36m";
in
rec {
  help = writeShellScriptBin "help" ''
    echo
    echo 'Convenient shell scripts:'
    # gpg guide echo ' * start-guide - displays a guide downloaded from https://github.com/drduh/YubiKey-Guide'
    echo ' * setup-gpg - download gpg.conf'
    echo ' * provision-yubikeys-gpg - create master and smartcard subkeys for use with GnuPG'
    echo ' * provision-yubikeys-ssh - create a private/public keypair with U2F (FIDO2) for use with SSH'
    echo ' * rotate-yubikeys - NOT YET SUPPORTED'
  '';

  guide-html = stdenv.mkDerivation {
    # name = "yubikey-guide-HEAD.html";
    # Fetch the latest version of drduh's yubikey guide (impure!)
    # src = builtins.fetchGit {
    #   url = "git://github.com/drduh/YubiKey-Guide";
    #   ref = "master";
    # };
    name = "yubikey-guide-2020-07-27.html";
    src = fetchFromGitHub {
      owner = "drduh";
      repo = "YubiKey-Guide";
      rev = "78164e8bfdea181cec6186fb5099406030ce19a3";
      sha256 = "0wgi2yszsm2vxj62ir8bkal0rmgvcnq1znp03fx1mhigpbvk2byx";
    };
    buildInputs = [ pandoc ];
    installPhase = "pandoc -t html4 --highlight-style pygments -s --toc README.md -o $out";
  };

  guide-readme = fetchurl {
    url = "https://raw.githubusercontent.com/drduh/YubiKey-Guide/78164e8bfdea181cec6186fb5099406030ce19a3/README.md";
    sha256 = "1xrb7clbhdbv65n4y0a3imlpslxvhw43mhfldglwa81h1jndfgwc";
  };

  browse-guide-html = writeShellScriptBin "browse-guide-html" ''
    ${midori}/bin/midori ${guide-html}
    '';

  browse-guide-readme = writeShellScriptBin "browse-guide-readme" ''
    ${mdcat}/bin/mdcat ${guide-readme} | less -r
    '';

  gpg-conf = fetchurl {
    url = "https://raw.githubusercontent.com/drduh/config/f27aae1aca5437506eb398b4d4194a380a344e1e/gpg.conf";
    sha256 = "0pskb5dz5gxxcpg384fm3h911xg6f4wapp89akqzfh81yiqib8yc";
  };

  setup-gpg = writeShellScriptBin "setup-gpg" ''
    # GNUPGHOME=/run/user/$(id -u)/gnupghome
    # GNUPGHOME=$(mktemp -d)
    GNUPGHOME="$(pwd)/gpghome"
    if [ ! -d $GNUPGHOME ]; then
      mkdir $GNUPGHOME
    fi
    if [ -f $GNUPGHOME/gpg.conf ]; then
      echo
      echo "$GNUPGHOME/gpg.conf already exists"
      echo
      exit 1
    fi
    cp ${gpg-conf} "$GNUPGHOME/gpg.conf"
    echo
    printf "\$GNUPGHOME has been set up for you. Generated keys will be in ${white}$GNUPGHOME${nc}.\n"
    echo
  '';

  provision-yubikeys-gpg = writeShellScriptBin "provision-yubikeys-gpg" ''

    wait_enter() { printf '${white}Continue? [ENTER] ${brown}(Ctrl+C quits)${nc}'; read; }

    echo
    echo 'This script loosely follows the structure described in'
    echo 'https://github.com/drduh/YubiKey-Guide/blob/1b5a2fefd8f1878398d9713c0608523be7d4799f/README.md'
    echo 'but with modifications'
    echo
    printf '${yellow}Warning:${nc}\n'
    echo
    echo '         This version was created to suit my own needs, you likely will not be able to use it'
    echo '         unless you deeply understand this script and the ritual it describes in each step.'
    echo
    echo '         In other words, it'"'"'s not intended for casual users, nor even experts.'
    echo '         You may not be able to recover your keys if you use it.'
    echo
    wait_enter
    echo

    mkdir -p ./gpghome
    # GNUPGHOME=/run/user/$(id -u)/gnupghome
    # GNUPGHOME=$(mktemp -d)
    GNUPGHOME="$(pwd)/gpghome"
    if [ ! -f "$GNUPGHOME/gpg.conf" ]; then
      printf "$GNUPGHOME/gpg.conf not found. Run ${white}setup-gpg${nc} first.\n"
      echo
      exit 1
    fi
    echo 'GNUPGHOME='$GNUPGHOME
    echo
    wait_enter
    echo

    echo '# Entropy'
    echo 'cat /proc/sys/kernel/random/entropy_avail'
    echo
    cat /proc/sys/kernel/random/entropy_avail
    echo
    wait_enter
    echo

    echo 'Use OneRNG with a hardware random number generator:'
    echo 'SKIPPED (see guide)'
    echo
    wait_enter
    echo

    echo '# Creating keys'
    echo 'grep -ve "^#" $GNUPGHOME/gpg.conf'
    echo
    grep -ve "^#" $GNUPGHOME/gpg.conf
    echo
    wait_enter
    echo

    echo '# Generate offline keychain (1 offline certify/sign master key, 1 offline decryption subkey)'
    echo
    printf '${yellow}Warning:${nc}\n'
    echo
    echo '         This differs wildly from the guide!'
    echo '         Your offline keys will not be stored electronically.'
    echo '         Instead we generate 5 paperkey shares that you can write down and'
    echo '         store in separate locations.'
    echo
    echo '         The offline decryption subkey can be used to encrypt data you want to store safely,'
    echo '         but not communicate with anyone. Since it is extremely tedious to actually use the'
    echo '         offline keychain it'"'"'s recommended that you also use keychain A and/or keychain B'
    echo '         to encrypt the same data.'
    echo '         That way you only need to use the offline key as a last-ditch'
    echo '         fallback in case disaster strikes and you'"'"'ve lost access to keychains A and B.'
    echo '         This relies on you to safely store your offline keys!'
    echo
    echo '         In an emergency (or to sign new keys), the offline keys can be'
    echo '         manually imported using:'
    echo
    printf '${white}'
    echo '         1. This live disk (on an air gapped computer)'
    printf '${nc}'
    echo
    printf '${white}'
    echo '         2. Any 3 of the 5 paperkey shares'
    printf '${nc}'
    echo
    printf '${white}'
    echo '         3. The pubring file offline-public-keys.asc'
    printf '${nc}'
    echo '         Since your pubring can be public, consider uploading it to a keyserver'
    echo '         using an internet-connected computer.'
    echo
    printf '${white}'
    echo '         4. The (optional) password that encrypts your offline keys.'
    printf '${nc}'
    echo '         If your offline gpg key has a passphrase, then so does your paperkey.'
    echo '         You need to remember this passphrase!'
    echo
    wait_enter
    echo

    printf '${yellow}Warning:${nc}\n'
    echo
    echo '         Note that the import procedure isn'"'"'t currently scripted or documented.'
    echo '         Make sure you properly understand how this script generates paperkey shares'
    echo '         via paperkey and mnemonicode.'
    echo '         You will need to robustly store the offline-public-keys.asc somewhere in'
    echo '         order to properly reconstitute your master key.'
    echo
    printf '${white}Note:${nc}\n'
    echo
    echo '         Your offline key includes a master key with certify & sign capability as'
    echo '         well as an encryption subkey.'
    echo
    wait_enter
    echo
    echo 'gpg --expert --full-generate-key'
    echo
    echo 'Instructions:'
    echo ' * Selections:'
    echo '     (9) ECC and ECC'
    echo '     (1) Curve 25519'
    echo ' * Correct?: y'
    echo ' * Real name / Email address / Comment'
    echo ' * Selections:'
    echo '     (O)kay'
    echo ' * Enter and confirm password (optional)'
    echo
    wait_enter
    echo

    gpg --expert --full-generate-key
    echo
    echo '# Enter KEYID listed above: '
    read KEYID
    echo 'KEYID='$KEYID
    echo

    # echo '# Store offline keys (3-of-5 paperkey shares)'
    # printf '${yellow}Warning:${nc}\n'
    # echo
    # echo '         This is not from the guide! It assumes you'll use a paperkey shares to store the offline keys.'
    # echo
    # printf '${yellow}Warning:${nc}\n'
    # echo
    # echo 'gpg --export-secret-key $KEYID | paperkey'
    # wait_enter
    # gpg --export-secret-key $KEYID | (printf '${bright_red}' ; paperkey ; printf '${nc}')
    # echo
    # printf '${white}Storage procedure:${nc}\n'
    # printf '${bright_blue}\n'
    # echo 'Write down the above key and store it somewhere safe'
    # echo
    # echo ' * It'"'"'s up to you to make sure you remember the passphrase and safely store the paperkey.'
    # echo ' * (Your memory is not as good as you think it is!)'
    # echo '   For example, try to remember a password from 5 years ago...'
    # echo ' * This script does not create backups of the subkeys stored on your yubikey(s). That is why multiple yubikey(s) are recommended.'
    # echo ' * The master key only protects identity. It cannot be used to decrypt data encrypted with you subkeys (stored on yubikeys(s)).'
    # printf '${nc}'
    # wait_enter
    # echo
    # echo ' TODO: COPY PUBRING TO USB '
    # echo

    # echo '# Sign offline master key with a (pre)existing key (optional)'
    # echo 'SKIPPED (see guide)'
    # wait_enter

    # echo '# Generate yubikey keychain A (1 sign/certify/authenticate/encrypt key, stored on 2 yubikeys)
    # echo
    # printf '${yellow}Warning:${nc}\n'
    # echo
    # echo '         This differs wildly from the guide!'
    # echo '         This step generates a set of keys for every day use and communication'
    # echo '         over the internet.'
    # echo '         If you need to give someone your public key, give them this one.'
    # echo
    # printf '${yellow}Warning:${nc}\n'
    # echo
    # echo '         Note that the import procedure isn't currently scripted or documented.'
    # echo '         Make sure you properly understand how this script generates paperkey shares'
    # echo '         via paperkey and mnemonicode.'
    # echo '         You will need to robustly store the offline-public-keys.asc somewhere in'
    # echo '         order to properly reconstitute your master key.'
    # echo
    # printf '${white}Note:${nc}\n'
    # echo '         Your offline key includes a master key with certify & sign capability as'
    # echo '         well as an encryption subkey.'
    # echo
    # echo 'gpg --expert --full-generate-key'
    # echo
    # echo 'Instructions:'
    # echo ' * Selections:'
    # echo '     (9) ECC and ECC'
    # echo '     (1) Curve 25519'
    # echo ' * Correct?: y'
    # echo ' * Real name / Email address / Comment'
    # echo ' * Selections:'
    # echo '     (O)kay'
    # echo ' * Enter and confirm password (optional)'
    # wait_enter
    # gpg --expert --full-generate-key
    # echo
    # echo 'Enter KEYID listed above: '
    # read KEYID
    # echo 'KEYID='$KEYID
    # echo



    # echo '# Sub-keys'
    # echo 'gpg --expert --edit-key $KEYID'
    # echo
    # echo 'Notes:'
    # echo ' * Use 4096-bit RSA keys'
    # echo ' * Use a 1 year expiration for sub-keys.'
    # echo '   (See Rotating keys in guide)'
    # echo
    # echo '## Signing'
    # echo
    # echo 'Instructions:'
    # echo ' * gpg> addkey'
    # echo ' * Selections:'
    # echo '     (4) RSA (sign only)'
    # echo ' * Keysize: 4096'
    # echo ' * Valid for: 1y'
    # echo ' * Correct?: y'
    # echo ' * Really?: y'
    # echo ' * Enter and confirm password'
    # echo
    # echo '## Encryption'
    # echo
    # echo 'Instructions:'
    # echo ' * gpg> addkey'
    # echo ' * Selections:'
    # echo '     (6) RSA (encrypt only)'
    # echo ' * Keysize: 4096'
    # echo ' * Valid for: 1y'
    # echo ' * Correct?: y'
    # echo ' * Really?: y'
    # echo ' * Enter and confirm password'
    # echo
    # echo '## Authentication'
    # echo
    # echo 'Instructions:'
    # echo ' * gpg> addkey'
    # echo ' * Selections:'
    # echo '     (8) RSA (set your own capabilities)'
    # echo '     (S) Toggle sign capability'
    # echo '     (E) Toggle encrypt capability'
    # echo '     (A) Toggle authenticate capability'
    # echo '     (Q) Finished'
    # echo ' * Keysize: 4096'
    # echo ' * Valid for: 1y'
    # echo ' * Correct?: y'
    # echo ' * Really?: y'
    # echo ' * Enter and confirm password'
    # echo
    # echo 'Save:'
    # echo ' * gpg> save'
    # echo
    # echo '## Add extra emails'
    # echo 'SKIPPED (see guide)'
    # wait_enter
    # gpg --expert --edit-key $KEYID

    # echo '# Verify'
    # echo 'gpg -K'
    # wait_enter
    # gpg -K


    # echo '## Upload the public key to a public keyserver'
    # echo 'gpg --send-key $KEYID'
    # wait_enter
    # echo 'gpg --keyserver pgp.mit.edu --send-key $KEYID'
    # wait_enter
    # echo 'gpg --keyserver keys.gnupg.net --send-key $KEYID'
    # wait_enter
    # echo 'gpg --keyserver hkps://keyserver.ubuntu.com:443 --send-key $KEYID'
    # wait_enter
  '';

  provision-yubikeys-ssh = writeShellScriptBin "provision-yubikeys-ssh" ''
    GNUPGHOME=/run/user/$(id -u)/gnupghome

    wait_enter() { printf '${white}Continue? [ENTER] ${brown}(Ctrl+C quits)${nc}'; read; }

    echo
    echo 'This script loosely follows instructions in'
    echo 'https://cryptsus.com/blog/how-to-configure-openssh-with-yubikey-security-keys-u2f-otp-authentication-ed25519-sk-ecdsa-sk-on-ubuntu-18.04.html'
    echo 'but with modifications'
    echo
    printf '${yellow}Warning:${nc}\n'
    echo
    echo '         This version was created to suit my own needs, you likely will not be able to use it'
    echo '         unless you deeply understand this script and the ritual it described in each step.'
    echo
    echo '         In other words, it'"'"'s not intended for casual users, nor even experts.'
    echo '         You may not be able to recover your keys if you use it.'
    echo
    wait_enter
    echo

    printf '# Check the version of OpenSSH: It should be ${white}8.2${nc} or higher\n'
    echo
    echo '${lsb-release}/bin/lsb_release -d && ssh -V'
    echo
    ${lsb-release}/bin/lsb_release -d && ssh -V
    echo
    wait_enter
    echo

    printf '# Check the firmware version of the plugged in yubikey: Require firmware version ${white}5.23${nc} or higher to support ed25519-sk\n'
    echo
    echo '${usbutils}/bin/lsusb -v 2>/dev/null | grep -A2 Yubico | grep '"'"'bcdDevice'"'"' | awk '"'"'{print $2}'"'"
    echo
    ${usbutils}/bin/lsusb -v 2>/dev/null | grep -A2 Yubico | grep 'bcdDevice' | awk '{print $2}'
    echo
    wait_enter
    echo

    echo
    echo '# Enter the physical yubikey number written on the device:'
    read PHYSICAL_YUBIKEY_NUMBER
    echo 'PHYSICAL_YUBIKEY_NUMBER='$PHYSICAL_YUBIKEY_NUMBER
    echo
    echo
    wait_enter
    echo

    echo '# Generate a ed25519-sk key'
    echo
    echo 'mkdir -p ./keys'
    mkdir -p ./keys
    echo
    echo "ssh-keygen -t ed25519-sk -C \"yubikey-$(date +'%Y-%m-%d')-$PHYSICAL_YUBIKEY_NUMBER\" -f \"./keys/id_yubikey_$PHYSICAL_YUBIKEY_NUMBER\""
    echo
    ssh-keygen -t ed25519-sk -C \"yubikey-$(date +'%Y-%m-%d')-$PHYSICAL_YUBIKEY_NUMBER\" -f "./keys/id_yubikey_$PHYSICAL_YUBIKEY_NUMBER"
    echo
    echo 'ls ./keys'
    echo
    ls ./keys
    echo
    wait_enter
    echo
  '';
}
